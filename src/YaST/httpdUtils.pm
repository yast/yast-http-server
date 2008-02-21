package YaST::httpdUtils;
use YaST::YCP;
use YaPI;
textdomain "http-server";

YaST::YCP::Import ("SuSEFirewall");
YaST::YCP::Import ("NetworkInterfaces");
YaST::YCP::Import ("Progress");
YaST::YCP::Import ("SCR");

# internal only
sub getFileByHostid {
    my $self = shift;
    my $hostid = shift;
    my $vhost_files = shift;

    foreach my $k ( keys(%$vhost_files) ) {
        foreach my $hostHash ( @{$vhost_files->{$k}} ) {
            return $k if( exists($hostHash->{HOSTID}) and $hostHash->{HOSTID} eq $hostid );
        }
    }
    return $self->SetError( summary => __('host not found'),
                            code => 'PARAM_CHECK_FAILED' );
}

sub isVirtualByName {
    my $self = shift;
    my $addr = shift;
    my $vhost_files = shift;

    my $filename = $self->getFileByHostid( 'main', $vhost_files );
    return 0 if( not ref($vhost_files->{$filename}) or
                 not ref($vhost_files->{$filename}->[0]) );
    foreach my $e ( @{$vhost_files->{$filename}->[0]->{DATA}} ) {
        if( $e->{KEY} eq 'NameVirtualHost' and
            $e->{VALUE} eq $addr ) {
            return 1;
        }
    }
    return 0;
}

# internal only
sub checkHostmap {
    my $self = shift;
    my $host = shift;

    my %checkMap = (
        ServerAdmin  => qr/^[^@]+@[^@]+$/,
        ServerName   => qr/^[\w\d.-]+$/,
#        SSL          => qr/^[012]$/,
        # more to go
    );

#    my $ssl = 0;
#    my $nb_vh = 0;
#    my $dr = 0;
#    my $sn = 0;
    foreach my $entry ( @$host ) {
        next unless( exists($checkMap{$entry->{KEY}}) );
        my $re = $checkMap{$entry->{KEY}};
        if( $entry->{VALUE} !~ /$re/ ) {
            return $self->SetError( summary => sprintf( __("Illegal '%s' parameter"), $entry->{KEY} ), 
                                    code    => "PARAM_CHECK_FAILED" );
        }
#        $ssl = $entry->{VALUE} if( $entry->{KEY} eq 'SSL' );
#        $nb_vh = $entry->{VALUE} if( $entry->{KEY} eq 'VirtualByName' );
#        $dr = 1 if(  $entry->{KEY} eq 'DocumentRoot' );
#        $sn = 1 if(  $entry->{KEY} eq 'ServerName' );
    }
    return $self->SetError( summary => __('ssl together with "virtual by name" is not possible'),
                            code    => 'PARAM_CHECK_FAILED' ) if( $ssl and $nb_vh );

    return 1;
}

# internal only!
sub readHosts {
    my $self = shift;
    my @data = SCR->Read('.http_server.vhosts');

    # this is a hack.
    # yast will put some directives in define sections
    # automatically and here we remove them

#    if( ref($data[0]) eq 'HASH' ) {
#        foreach my $file ( keys %{$data[0]} ) {
#            foreach my $host ( @{$data[0]->{$file}} ) {
#                foreach my $data ( @{$host->{DATA}} ) {
#                    if( exists($data->{OVERHEAD}) and
#                        $data->{OVERHEAD} =~ /# YaST auto define section/ ) {
#                        $data = $data->{VALUE}->[0]; # delete the "auto define" section
#                    }
#                }
#            }
#        }
#    }


    return @data;
}

# internal only!
sub writeHost {
    my $self = shift;
    my $filename = shift;
    my $vhost_files = shift;

    foreach my $host ( @{$vhost_files->{$filename}} ) {
        my @newData = ();
        foreach my $data ( @{$host->{DATA}} ) {
            my $define = $self->define4keyword( $data->{KEY}, 'defines' );
            my $module = $self->define4keyword( $data->{KEY}, 'module' );
            if( $define || $module ) {
                # either IfDefine or IfModule is possible. Not both at the same time
                my $secName = ($define)?('IfDefine'):('IfModule');
                my $param   = ($define)?($define):($module);
                my %h = %$data;
                push( @newData, { 'OVERHEAD'     => "# YaST auto define section\n",
                          'SECTIONNAME'  => $secName,
                          'SECTIONPARAM' => $param,
                          'KEY'          => '_SECTION',
                          'VALUE'        => [ \%h ]
                } );
            } elsif( $data->{KEY} eq 'HostIP' ) {
                $host->{HostIP} = $data->{VALUE};
            } else {
                push( @newData, $data );
            }
        }
        $host->{DATA} = \@newData;
    }
    my $ret = SCR->Write(".http_server.vhosts.setFile.$filename", $vhost_files->{$filename} );
    unless( $ret ) {
        my %h = %{SCR->Error(".http_server")};
        return $self->SetError( %h );
    }

    # write default-server.conf always because of Directory Entries
    unless( $filename eq 'default-server.conf' ) {
        $ret = $self->writeHost( 'default-server.conf', $vhost_files );
        unless( $ret ) {
            my %h = %{SCR->Error(".http_server")};
            return $self->SetError( %h );
        }
    }

    return 1;
}

sub define4keyword {
    my $self = shift;
    my $keyword = shift;
    my $what = shift;
    foreach my $mod ( keys( %YaPI::HTTPDModules::modules ) ) {
        if( exists( $YaPI::HTTPDModules::modules{$mod}->{$what} ) ) {
            if( exists( $YaPI::HTTPDModules::modules{$mod}->{$what}->{$keyword} ) ) {
                return $YaPI::HTTPDModules::modules{$mod}->{$what}->{$keyword};
            } else {
                return undef;
            }
        }
    }
}

# internal only
sub selections2modules {
    my $self = shift;
    my $list = shift;
    my @ret;
    foreach my $sel ( @$list ) {
        if( $sel and exists( $YaPI::HTTPDModules::selection{$sel} ) ) {
            push( @ret, @{$YaPI::HTTPDModules::selection{$sel}->{modules}} );
        }
    }
    return @ret;
}

# internal only
sub ip2device {
    my $self = shift;
    my %ip2device;
    Progress->off();
    SuSEFirewall->Read();
    NetworkInterfaces->Read();
    my $devices = NetworkInterfaces->Locate("BOOTPROTO", "static");
    foreach my $dev ( @$devices ) {
        my $ip = NetworkInterfaces->GetValue($dev, "IPADDR");
        $ip2device{$ip} = $dev if( $ip );
    }
    Progress->on();
    return \%ip2device;
}

sub ModifyHostKey {
    my $self = shift;
    my $host = shift;
    my $key  = shift;
    my $val  = shift;

    for( my $i=0; $i < @$host; $i++ ) {
        if( $host->[$i]->{KEY} eq $key ) {
            if( not defined $val ) {
                splice( @$host, $i, 1 );
            } else {
                $host->[$i]->{VALUE} = $val;
            }
            return 1;
        }
    }
    push( @$host, { KEY => $key, VALUE => $val } ) if( defined $val );
    return 0;
}

sub FetchHostKey {
    my $self = shift;
    my $host = shift;
    my $key = shift;

    foreach my $k ( @$host ) {
	if ( ref($k->{VALUE}) eq "ARRAY" && $k->{SECTIONPARAM} eq "SSL" ) { 
		foreach my $line (@{$k->{VALUE}}) {
		return $line->{VALUE} if ($line->{KEY} eq $key); 
		}
	}
        next unless( $k->{KEY} eq $key );
        return $k->{VALUE};
    }
    return undef;
}

