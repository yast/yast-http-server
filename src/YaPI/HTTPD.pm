=head1 NAME

YaPI::HTTPD

=head1 PREFACE

This package is the public Yast2 API to configure the apache2.

=head1 SYNOPSIS

use YaPI::HTTPD

$hostList = GetHostsList()

  returns an array reference of host id strings or
  undef on failure.

$hostData = GetHost($hostid)

  returns a host hash with all settings of the host or
  undef on failure

ModifyHost($host_id,$hostData)

  modifies the host with $host_id.
  $hostData is an array reference containing the data.
  This function returns undef on failure

CreateHost($host_id,$host_hash)

  creates a new host with $host_id
  $host_hash is a hash reference containing the data
  This function returns undef on failure

DeleteHost($host_id)

  the host with $host_id is getting deleted
  This function returns undef on failure

$modList = GetModuleList()

  returns a list of strings with all enabled modules

$knownMods = GetKnownModules()

  returns a list of maps with all known modules

ModifyModuleList($moduleList,$state)

  $moduleList is a list of module name strings
  $state is a boolean for enable/disable the modules in list
  This function returns undef on failure

$knownSel = GetKnownModuleSelections()

  returns a list of strings with all known predefined selections

$selList = GetModuleSelectionsList()

  returns a list of all activated predefined module selections

ModifyModuleSelectionList($selectionList,$state)

  $selectionList is a list of predefined module selections
  $state is a boolean for enable/disable the selections in list

ModifyService($state)

  $state is a boolean for enable/disable the apache2 runlevel script

$serviceState = ReadService()

  returns the state of the apache2 runlevel script as a boolean

CreateListen($fromPort,$toPort,$address,$doFirewall)

  $fromPort and $toPort are the listen ports. They can be the same.
  $address is the bind address and can be an empty string for 'all'
  $doFirewall is a boolean to write the listen data to the SuSEFirewall2

DeleteListen($fromPort,$toPort,$address,$doFirewall)

  $fromPort and $toPort are the listen ports. They can be the same.
  $address is the bind address and can be an empty string for 'all'
  $doFirewall is a boolean to delete the listen data from the SuSEFirewall2

$curListen = GetCurrentListen()

  returns a list of hashes with the listen data
  Hash keys are ADDRESS and PORT

$spackList = GetServicePackages()

  returns a list of packages needed for this service
  (dependencies are not solved)

$mpackList = GetModulePackages()

  returns a list of packages needed for the modules
  (dependencies are not solved)

GetErrorLogFiles()

  not implemented yet

GetAccessLogFiles()

  not implemented yet

GetTransferLogFiles()

  not implemented yet

$params = GetServerFlags()

  returns a string with the apache2 startparameter

SetServerFlags($param)

  sets the apache2 startparameter to $param

WriteServerCert($hostId,$pemData)

  write the server certificate and optional key for
  $hostID.

WriteServerKey($hostId,$pemData)

  write the server private key and optional certificate
  for $hostID.

WriteServerCA($hostId,$pemData)

  write the server CA

$pemData = ReadServerCert($hostId)

  read the server certificate. The certificate
  is returned as a scalar in PEM format.

$pemData = ReadServerKey($hostId)

  read the server key. The key is returned as
  a scalar in PEM format.

$pemData = ReadServerCA($hostId)

  read the server CA. The CA is returned as
  a scalar in PEM format.

B<Host Data array>

Each hash has at least the following keys:

 KEY   => apache2 configuration directive like 'ServerAdmin'
 VALUE => the value of the configuration directive like 'admin@mydom.de'

the following keys are optional

 OVERHEAD => a comment in the config file above the KEY/VALUE directive

The following keys are not mapped 1:1 from the configfile, but are
derived from real apache2 directives

 KEY   = SSL
 VALUE = 0,1 or 2

turns on/off SSL for the host.

0 = SSL is turned off

1 = SSL is turned on but SSL is not required

2 = SSL is turned on and SSL is required for every connection

 KEY   = VirtualByName
 VALUE = 0,1

indicates if this is a virtual by name host. If this is 0, it's an
IP based virtual host.

B<Host id>

Every host has an so called host id which is used to identify and make
it unique to the API.
So the host id can not be choosen out of the blue but has a fix structure:

    vhost_entry/servername

For example

    *:80/myserver.mydom.de
    192.168.0.10:80/internal.mydom.de

The part in front of the slash is the virtual host
part and will appear behind the "VirtualHost" directive
in the config file. The part behind the slash is the
servername. So for the examples above, the apache2 config
will look like this:

    <VirtualHost *:80>
        ServerName myserver.mydom.de
    </VirtualHost>

    <VirtualHost 192.168.0.10:80>
        ServerName internal.mydom.de
    </VirtualHost>

there is just one host id that breaks this nameing schema and
that is the "default" host. Everything in the default host
will not end in a VirtualHost section.
You can not create or delete the default host id.

=head1 DESCRIPTION

=over 2

=cut

package YaPI::HTTPD;
BEGIN { push( @INC, '/usr/share/YaST2/modules/' ); }
@YaPI::HTTPD::ISA = qw( YaPI );
use YaPI;
use YaST::YCP;
use YaPI::HTTPDModules;
YaST::YCP::Import ("SCR");
YaST::YCP::Import ("Service");
YaST::YCP::Import ("SuSEFirewall");
YaST::YCP::Import ("NetworkDevices");
YaST::YCP::Import ("Progress");

#######################################################
# temoprary solution end
#######################################################
our $VERSION="0.01";
our %TYPEINFO;

use strict;
use Errno qw(ENOENT);

#######################################################
# default and vhost API start
#######################################################
my $vhost_files;

# internal only
sub getFileByHostid {
    my $self = shift;
    my $hostid = shift;
    foreach my $k ( keys(%$vhost_files) ) {
        foreach my $hostHash ( @{$vhost_files->{$k}} ) {
            return $k if( exists($hostHash->{HOSTID}) and $hostHash->{HOSTID} eq $hostid );
        }
    }
    return $self->SetError( summary => 'host not found' );
}

# internal only
sub checkHostmap {
    my $self = shift;
    my $host = shift;

    my %checkMap = (
        ServerAdmin  => qr/^[^@]+@[^@]+$/,
        ServerName   => qr/^[a-zA-Z\d.-]+$/,
        SSL          => qr/^[012]$/,
        # more to go
    );

    my $ssl = 0;
    my $nb_vh = 0;
    my $dr = 0;
    my $sn = 0;
    foreach my $entry ( @$host ) {
        next unless( exists($checkMap{$entry->{KEY}}) );
        my $re = $checkMap{$entry->{KEY}};
        if( $entry->{VALUE} !~ /$re/ ) {
            return $self->SetError( summary => "illegal '$entry->{KEY}' parameter" );
        }
        $ssl = $entry->{VALUE} if( $entry->{KEY} eq 'SSL' );
        $nb_vh = $entry->{VALUE} if( $entry->{KEY} eq 'VirtualByName' );
        $dr = 1 if(  $entry->{KEY} eq 'DocumentRoot' );
        $sn = 1 if(  $entry->{KEY} eq 'ServerName' );
    }
    return 0 if( $ssl and $nb_vh ); # ssl + virtual by name is not possible

    return 1;
}

=item *
C<$hostList = GetHostsList();>

This function returns a reference to a list of strings of all host ids.
Even without any virtual host, there is always the "default"
host id for the default host.
On error, undef is returned and the Error() function can be used
to get the error hash.

EXAMPLE:

 my $list = GetHostsList();
 if( not defined($list) ) {
     return Error();
 }
 foreach my $hostid ( @$list ) {
     print "ID: $hostid\n";
 }

=cut

BEGIN { $TYPEINFO{GetHostsList} = ["function", [ "list", "string"] ]; }
sub GetHostsList {
    my $self = shift;
    my @ret = ();
    my @data = $self->readHosts();

    if( ref($data[0]) eq 'HASH' ) {
        foreach my $hostList ( values(%{$data[0]}) ) {
            foreach my $hostentryHash ( @$hostList ) {
                push( @ret, $hostentryHash->{HOSTID} ) if( $hostentryHash->{HOSTID} );
            }
        }
    } else {
        return $self->SetError( summary => 'SCR Agent parsing failed' );
    }
    return \@ret;
}

=item *
C<$hostData = GetHost($hostid);>

This function returns a host data list.

EXAMPLE

 # dumping all configured hosts
 my $hostList = GetHostsList();
 if( not defined $hostList ) {
     # error
 }
 foreach my $hostid ( @$hostList ) {
     my @host = GetHost( $hostid );
     print "# dumping $hostid\n";
     foreach my $directive ( @host ) {
         print $directive->{OVERHEAD}."\n";
         print $directive->{KEY}.' '.$directive->{VALUE}."\n";
     }
 }

=cut

BEGIN { $TYPEINFO{GetHost} = ["function", ["list", [ "map", "string", "any" ] ], "string"]; }
sub GetHost {
    my $self = shift;
    my $hostid = shift;

    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = $self->readHosts();

    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return $self->SetError( summary => 'SCR Agent parsing failed' );
    }

    my $filename = $self->getFileByHostid( $hostid );
    return $self->SetError( summary => 'hostid not found' ) unless( $filename );
    foreach my $hostHash ( @{$vhost_files->{$filename}} ) {
        if( $hostHash->{HOSTID} eq $hostid ) {
            use Data::Dumper;
            print Data::Dumper->Dump( [ $hostHash ] );
            my $vbnHash = { KEY => 'VirtualByName', VALUE => $hostHash->{'VirtualByName'} };
            my $sslHash = { KEY => 'SSL', VALUE => 0 };
            my $overheadHash = { KEY => 'OVERHEAD', VALUE => $hostHash->{'OVERHEAD'} };
            my $sslEngine = 'off';
            my @newHH = ();
            foreach my $h ( @{$hostHash->{'DATA'}} ) {
                if( $h->{'KEY'} eq 'SSLEngine' ) {
                    $sslEngine = $h->{'VALUE'};
                } else {
                    push( @newHH, $h );
                }
            }
            $hostHash->{'DATA'} = \@newHH;
            if( $sslEngine eq 'on' and grep( { $_->{KEY} eq 'SSLRequireSSL' } @{$hostHash->{'DATA'}} ) ) {
                delete($hostHash->{'DATA'}->{'SSLRequireSSL'});
                $sslHash->{'VALUE'} = 2;
            } elsif( $sslEngine eq 'on' ) {
                $sslHash->{'VALUE'} = 1;
            }
            return [ @{$hostHash->{'DATA'}}, $sslHash, $vbnHash ];
        }
    }
    return $self->SetError( summary => 'hostid not found' );
}

=item *
C<ModifyHost($hostid,$hostdata)>

This function modifies the host with $hostid.
The complete host data will be replaced with $hostdata.

EXAMPLE

 # turn off SSL and setting a comment in config file
 my @host = GetHost( $hostid );
 foreach my $directive ( @host ) {
     if( $directive->{KEY} eq 'SSL' ) {
         $directive->{VALUE} = 2;
         $directive->{OVERHEAD} = "# customer wants SSL to be required\n";
     }
 }
 ModifyHost( $hostid, \@host );

ATTENTION

If you change the ServerName directive, the host id will change 
automatically too.

HINT

A helper function like replaceKey might be helpful but is not provided
by the API.

 my @hostData = GetHost( $hostid );
 replaceKey( 'SSL', { KEY => 'SSL', VALUE => 1 }, \@hostData );
 replaceKey( 'ServerAdmin', { KEY => 'ServerAdmin', VALUE => 'my@my.dom' }, \@hostData );
 ModifyHost( $hostid, \@hostData );

 sub replaceKey {
     my $key      = shift;
     my $new      = shift;
     my $hostData = shift;
     my $found = 0;
 
     foreach( @$hostData ) {
         if( $_->{KEY} eq $new->{KEY} ) {
             $new->{OVERHEAD} = $_ ->{OVERHEAD} unless( exists($new->{OVERHEAD}) );
             $_ = $new;
             $found = 1;
             last;
         }
     }
     push( @$hostData, $new ) unless( $found );
     return 1;
 }

=cut

BEGIN { $TYPEINFO{ModifyHost} = ["function", "boolean", "string", [ "list", [ "map", "string", "any" ] ] ]; }
sub ModifyHost {
    my $self = shift;
    my $hostid = shift;
    my $newData = shift;

    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = $self->readHosts();
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return $self->SetError( summary => 'SCR Agent parsing failed' );
    }

    my $filename = $self->getFileByHostid( $hostid );
    return undef if( not $self->checkHostmap( $newData ) );
    foreach my $entry ( @{$vhost_files->{$filename}} ) {
        if( $entry->{HOSTID} eq $hostid ) {
            my @tmp;
            foreach my $tmp ( @{$entry->{DATA}} ) {
                next unless( $tmp->{KEY} eq 'DocumentRoot' );
                $self->delDir( $tmp->{VALUE} );
                last;
            }
            foreach my $tmp ( @$newData ) {
                if( $tmp->{'KEY'} eq 'VirtualByName' ) {
                    $entry->{VirtualByName} = $tmp->{'VALUE'};
                    next;
                } elsif( $tmp->{'KEY'} eq 'SSL' ) {
                    if( $tmp->{'VALUE'} == 0 ) {
                        push( @tmp, { KEY => 'SSLEngine', VALUE => 'off' } );
                    } elsif( $tmp->{'VALUE'} == 1 ) {
                        push( @tmp, { KEY => 'SSLEngine', VALUE => 'on' } );
                    } elsif( $tmp->{'VALUE'} == 2 ) {
                        push( @tmp, { KEY => 'SSLEngine', VALUE => 'on' } );
                        push( @tmp, { KEY => 'SSLRequireSSL', VALUE => '' } );
                    }
                    next;
                } elsif( $hostid ne 'default' and $tmp->{KEY} =~ /ServerTokens|TimeOut|ExtendedStatus/ ) {
                    # illegal keys in vhost
                    return $self->SetError( "illegal key in vhost '$tmp->{KEY}'" );
                } elsif( $tmp->{'KEY'} eq 'DocumentRoot' ) {
                    $self->addDir( $tmp->{'VALUE'} );
                    push( @tmp, $tmp );
                } else {
                    push( @tmp, $tmp );
                }
            }
            $entry->{DATA} = \@tmp;
            $self->writeHost( $filename );

            # write sysconfig variables for default host
            # don't know why but we are safe then.
            if( $hostid eq 'default' ) {
                foreach my $tmp ( @tmp ) {
                    if( $tmp->{KEY} eq 'ServerAdmin' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_SERVERADMIN', $tmp->{'VALUE'});
                    } elsif( $tmp->{KEY} eq 'ServerName' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_SERVERNAME', $tmp->{'VALUE'} );
                    } elsif( $tmp->{KEY} eq 'ServerSignature' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_SERVERSIGNATURE', $tmp->{'VALUE'} );
                    } elsif( $tmp->{KEY} eq 'LogLevel' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_LOGLEVEL', $tmp->{'VALUE'} );
                    } elsif( $tmp->{KEY} eq 'UseCanonicalName' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_USE_CANONICAL_NAME', $tmp->{'VALUE'} );
                    } elsif( $tmp->{KEY} eq 'ServerTokens' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_SERVERTOKENS', $tmp->{'VALUE'} );
                    } elsif( $tmp->{KEY} eq 'ExtendedStatus' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_EXTENDED_STATUS', $tmp->{'VALUE'} );
                    } elsif( $tmp->{KEY} eq 'TimeOut' ) {
                        SCR->Write('.sysconfig.apache2.APACHE_TIMEOUT', $tmp->{'VALUE'} );
                    }
                }
            }
            return 1;
        }
    }
    return 0; # host not found. Error?
}

sub delDir {
    my $self = shift;
    my $dir = shift;
    my @newData = ();

    $dir =~ s/\/+/\//g;

    my $filename = $self->getFileByHostid( "default" );
    foreach my $entry ( @{$vhost_files->{$filename}} ) {
        foreach my $e ( @{$entry->{DATA}} ) {
            next if( $e->{KEY} eq '_SECTION' and
                     $e->{SECTIONNAME} eq 'Directory' and
                     $e->{SECTIONPARAM} =~ /^"*$dir\/*"*/ );
            push( @newData, $e );
        }
        $entry->{DATA} = \@newData;
    }
    return;
}

sub addDir {
    my $self = shift;
    my $dir = shift;
    $dir =~ s/\/+/\//g;
    $self->delDir( $dir ); # avoid double entries

    my $filename = $self->getFileByHostid( "default" );
    my $dirEntry = {
        'OVERHEAD'     => "# YaST created entry\n",
        'SECTIONNAME'  => 'Directory',
        'SECTIONPARAM' => "\"$dir\"",
        'KEY'   => '_SECTION',
        'VALUE' => [
                    {
                     'KEY'   => 'Options',
                     'VALUE' => 'None'
                    },
                    {
                     'KEY'   => 'AllowOverride',
                     'VALUE' => 'None'
                    },
                    {
                     'KEY'   => 'Order',
                     'VALUE' => 'allow,deny'
                    },
                    {
                     'KEY'   => 'Allow',
                     'VALUE' => 'from all'
                    }
                  ]
    };
    push( @{$vhost_files->{$filename}->[0]->{DATA}}, $dirEntry );
    return;
}

=item *
C<CreateHost($hostid,$hostdata)>

This function creates a host with $hostid. $hostdata is the host data
array.

ATTENTION

ServerName directive and host id must match. If not, the host will not
be created.

EXAMPLE

 my @newHost = (
                 { KEY => "ServerName",    VALUE => 'createTest2.suse.de' },
                 { KEY => "VirtualByName", VALUE => 1 },
                 { KEY => "ServerAdmin",   VALUE => 'no@one.de' }
               );
 CreateHost( '192.168.1.2/createTest2.suse.de', \@temp );

=cut

BEGIN { $TYPEINFO{CreateHost} = ["function", "boolean", "string", [ "map", "string", "any" ] ]; }
sub CreateHost {
    my $self = shift;
    my $hostid = shift;
    my $data = shift;

    if( ref($data) ne 'ARRAY' ) {
        return $self->SetError( summary => "data must be an array ref and not ".ref($data) );
    }

    my $sslHash = { KEY => 'SSLEngine' , VALUE => 'off' };
    my @tmp = ( $sslHash );
    my $VirtualByName = 0;
    my $docRoot = "";
    foreach my $key ( @$data ) {
        # VirtualByName and SSL get dropped/replaced
        if( $key->{KEY} eq 'VirtualByName' ) {
            $VirtualByName = $key->{VALUE};
        } elsif( $key->{KEY} eq 'SSL' and $key->{VALUE} == 1 ) {
            $sslHash->{'VALUE'} = 'on';
        } elsif( $key->{KEY} eq 'SSL' and $key->{VALUE} == 2 ) {
            $sslHash->{'VALUE'} = 'on';
            push( @tmp, { KEY => 'SSLRequireSSL', VALUE => '' } );
        } elsif( $key->{KEY} eq 'SSL' ) {
            # already set to "off" above. So ignore.
        } elsif( $key->{KEY} eq 'DocumentRoot' ) {
            $docRoot = $key->{VALUE};
            push( @tmp, $key );
        } elsif( $key->{KEY} =~ /ServerTokens|TimeOut|ExtendedStatus/ ) {
            # illegal keys in vhost
            return $self->SetError( "illegal key in vhost '$key->{KEY}'" );
        } else {
            push( @tmp, $key );
        }
    }
    $data = \@tmp;
    return undef if( not $self->checkHostmap( $data ) );

    $hostid =~ /^([^\/]+)/;
    my $vhost = $1;
    return $self->SetError( "illegal hostid" ) unless( $vhost );
    my $entry = {
                 OVERHEAD      => "# YaST generated vhost entry\n",
                 VirtualByName => $VirtualByName,
                 HOSTID        => $hostid,
                 VHOST         => $vhost,
                 DATA          => $data
    };
    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = $self->readHosts();
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return $self->SetError( summary => 'SCR Agent parsing failed' );
    }
    if( ref($vhost_files->{'yast2_vhosts.conf'}) eq 'ARRAY' ) {
        # merge new entry with existing entries in yast2_vhosts.conf
        push( @{$vhost_files->{'yast2_vhosts.conf'}}, $entry );
    } else {
        # create new yast2_vhosts.conf
        $vhost_files->{'yast2_vhosts.conf'} = [ $entry ];
    }
    $self->addDir( $docRoot );
    $self->writeHost( 'yast2_vhosts.conf' );
    return 1;
}

=item *
C<DeleteHost($hostid)>

This function removes the host with $hostid

EXAMPLE
 DeleteHost( '192.168.1.2/createTest2.suse.de' );

=cut

#bool DeleteHost( string hostid );
BEGIN { $TYPEINFO{DeleteHost} = ["function", "boolean", "string"]; }
sub DeleteHost {
    my $self = shift;
    my $hostid = shift;

    if( $hostid eq 'default' ) {
        return $self->SetError( summary => 'can not delete default host' );
    }
    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = $self->readHosts();
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return $self->SetError( summary => 'SCR Agent parsing failed' );
    }
    my $filename = $self->getFileByHostid( $hostid );
    my @newList = ();
    foreach my $hostHash ( @{$vhost_files->{$filename}} ) {
        if( exists($hostHash->{HOSTID}) and $hostHash->{HOSTID} ne $hostid ) {
            push( @newList, $hostHash );
        } else {
            foreach my $dat ( @{$hostHash->{DATA}} ) {
                if( $dat->{KEY} eq 'DocumentRoot' ) {
                    $self->delDir( $dat->{VALUE} );
                    last;
                }
            }
        }
    }
    if( @newList ) {
        $vhost_files->{$filename} = \@newList;
    } else {
        delete($vhost_files->{$filename}); # drop empty file
    }
    $self->writeHost( $filename );
    return 1;
}

# internal only!
sub readHosts {
    my $self = shift;
    my @data = SCR->Read('.http_server.vhosts');

    # this is a hack.
    # yast will put some directives in define sections
    # automatically and here we remove them
    if( ref($data[0]) eq 'HASH' ) {
        foreach my $file ( keys %{$data[0]} ) {
            foreach my $host ( @{$data[0]->{$file}} ) {
                foreach my $data ( @{$host->{DATA}} ) {
                    if( exists($data->{OVERHEAD}) and
                        $data->{OVERHEAD} =~ /^# YaST auto define section/ ) {
                        $data = $data->{VALUE}->[0]; # delete the "auto define" section
                    }
                }
            }
        }
    }
    return @data;
}

# internal only!
sub writeHost {
    my $self = shift;
    my $filename = shift;

    foreach my $host ( @{$vhost_files->{$filename}} ) {
        my @newData = ();
        foreach my $data ( @{$host->{DATA}} ) {
            my $define = $self->define4keyword( $data->{KEY} );
            if( $define ) {
                my %h = %$data;
                push( @newData, { 'OVERHEAD'     => "# YaST auto define section\n",
                          'SECTIONNAME'  => 'IfDefine',
                          'SECTIONPARAM' => $define,
                          'KEY'          => '_SECTION',
                          'VALUE'        => [ \%h ]
                } );
            } else {
                push( @newData, $data );
            }
        }
        $host->{DATA} = \@newData;
    }
    SCR->Write(".http_server.vhosts.setFile.$filename", $vhost_files->{$filename} );

    # write default-server.conf always because of Directory Entries
    my $def = $self->getFileByHostid( 'default' );
    SCR->Write(".http_server.vhosts.setFile.$def", $vhost_files->{$def} );
    return 1;
}

sub define4keyword {
    my $self = shift;
    my $keyword = shift;
    foreach my $mod ( keys( %YaPI::HTTPDModules::modules ) ) {
        if( exists( $YaPI::HTTPDModules::modules{$mod}->{defines} ) ) {
            if( exists( $YaPI::HTTPDModules::modules{$mod}->{defines}->{$keyword} ) ) {
                return $YaPI::HTTPDModules::modules{$mod}->{defines}->{$keyword};
            } else {
                return undef;
            }
        }
    }
}

#######################################################
# default and vhost API end
#######################################################


#######################################################
# apache2 modules API start
#######################################################

=item *
C<$moduleList = GetModuleList()>

this function returns a reference to an array of strings.
The list contains all active apache2 module names.

EXAMPLE

 my $modules = GetModuleList();
 if( $modules ) {
     foreach my $mod_name ( @$modules ) {
         print "active module: $mod_name\n";
     }
 }

=cut

BEGIN { $TYPEINFO{GetModuleList} = ["function", [ "list", "string" ] ]; }
sub GetModuleList {
    my $self = shift;
    my $data = SCR->Read('.sysconfig.apache2.APACHE_MODULES'); # FIXME: Error handling
    $data =~ s/mod_//g;

    return [ split(/\s+/, $data) ];
}

=item *
C<$moduleList = GetKnownModules()>

this function returns a reference to an array of hashes.
Each has has the following keys:

name      => name of the module
summary   => a description of the module
packages  => an array reference with all needed packages for this module
default   => a boolean that shows if this module is active by default
required  => a boolean that shows if this module is required
suggested => a boolean that shows if this module is suggested by SUSE
position  => a number that shows the position in the loading order

EXAMPLE

 # list all modules with enabled/disabled state
 my $knownMods  = GetKnownModules();
 my $activeMods = GetModuleList();
 my %activeMods = ();
 @activeMods{@$activeMods} = ();
 foreach my $km ( @$knownMods ) {
     my $state = (grep(/^$km$/, @$activeMods))?('on'):('off');
     delete($activeMods{$km});
     print "$km->{name} = $state\n";
 }

 # list active unknown mods now
 foreach my $m ( keys(%activeMods ) ) {
     print "$m = on\n";
 }

=cut

BEGIN { $TYPEINFO{GetKnownModules} = ["function", [ "list", ["map","string","any"] ] ]; }
sub GetKnownModules {
    my $self = shift;
    my @ret = ();
    foreach my $mod ( keys(%YaPI::HTTPDModules::modules) ) {
        push( @ret, { name => $mod, %{$YaPI::HTTPDModules::modules{$mod}} } );
        @ret = sort( { $a->{position} <=> $b->{position} } @ret );
    }
    return \@ret;
}

=item *
C<ModifyModuleList($moduleList, $state)>

with this function you can turn on and off modules of the apache2
$modulelist is an array reference to a list of modulenames.

EXAMPLE
 ModifyModuleList( [ 'perl' ], 1 );
 ModifyModuleList( [ 'php4' ], 0 );

=cut

BEGIN { $TYPEINFO{ModifyModuleList} = ["function", "boolean", [ "list","string" ], "boolean" ]; }
sub ModifyModuleList {
    my $self = shift;
    my $newModules = shift;
    my $enable = shift;

    my @newList = ();
    if( not $enable ) {
        foreach my $mod ( @{$self->GetModuleList()} ) {
            next if( grep( /^$mod$/, @$newModules ) );
            push( @newList, $mod );
        }
    } else {
        my @oldList = ( @{$self->GetModuleList()}, $self->selections2modules( $self->GetModuleSelectionsList() ) );
        my %uniq;
        @uniq{@oldList} = ();
        @oldList = keys( %uniq );
        foreach my $mod ( @$newModules ) {
            next if( grep( /^$mod$/, @oldList ) ); # already existing module?
            push( @oldList, $mod );
        }
        @newList = sort( {
                         my $aa = (exists($YaPI::HTTPDModules::modules{$a}))?($YaPI::HTTPDModules::modules{$a}->{position}):(10000000);
                         my $bb = (exists($YaPI::HTTPDModules::modules{$b}))?($YaPI::HTTPDModules::modules{$b}->{position}):(10000000);
                         $aa <=> $bb;
                        } @oldList );
    }

    SCR->Write('.sysconfig.apache2.APACHE_MODULES', join(' ',@newList));
    SCR->Write('.sysconfig.apache2', undef);
    return 1;
}

=item *
C<$knownSelList = GetKnownModuleSelections()>

this functions returns a reference to an array that
contains hashes with information about all known
module selections.
One hash has the following keys:

id      => name of the selection
summary => a describtion of the selection
modules => an array reference with the names of the modules
default => a boolean that shows if this selection is on by default

EXAMPLE

 my $knownSelList = GetKnownModuleSelections();
 foreach my $kms ( @$knownSelList ) {
     print "$kms->{id} = $kms->{summary}\n";
 }

=cut


BEGIN { $TYPEINFO{GetKnownModuleSelections} = ["function", [ "map","string","any" ] ]; }
sub GetKnownModuleSelections {
    my $self = shift;
    my @ret = ();
    foreach my $sel ( keys(%YaPI::HTTPDModules::selection) ) {
        push( @ret, { id => $sel, %{$YaPI::HTTPDModules::selection{$sel}} } );
    }
    return \@ret;
}

=item *
C<$selList = GetModuleSelectionsList()>

this functions returns a reference to an array that
contains strings with the names of the active module
seletcions.

EXAMPLE

 my $selList = GetModuleSelectionsList();
 print "active selections: ".join(',', @$selList)."\n";

=cut

BEGIN { $TYPEINFO{GetModuleSelectionsList} = ["function", ["list","string"] ]; }
sub GetModuleSelectionsList {
    my $self = shift;
    return (SCR->Read('.http_server.moduleselection'))[0];
}

=item *
C<ModifyModuleSelectionList($selList, $status)>

this function modifies the module selection list.
You can turn on and off module selections with the
boolean $status.
Changing the selections will directly influence the
module list.

EXAMPLE

 ModifyModuleSelectionList( ['perl-scripting', 'debug'],1  );
 ModifyModuleSelectionList( ['php4-scripting'], 0 );

=cut

BEGIN { $TYPEINFO{ModifyModuleSelectionList} = ["function", "boolean", ["list","string"], "boolean" ]; }
sub ModifyModuleSelectionList {
    my $self = shift;
    my $newSelection = shift;
    my $enable = shift;
    my %uniq = ();

    @uniq{@{$self->GetModuleSelectionsList()}} = ();
    if( $enable ) {
        @uniq{@$newSelection} = ();
        foreach my $ns ( @$newSelection ) {
            $self->ModifyModuleList( $HTTPModules::selection{$ns}->{modules}, 1 );
            $self->ModifyModuleList( [], 1 );
        }
    } else {
        delete(@uniq{@$newSelection});
        foreach my $ns ( @$newSelection ) {
            $self->ModifyModuleList( $HTTPModules::selection{$ns}->{modules}, 0 );
            $self->ModifyModuleList( [], 1 );
        }
    }

    SCR->Write('.http_server.moduleselection', [keys(%uniq)]);
}

# internal only
sub selections2modules {
    my $self = shift;
    my $list = shift;
    my @ret;
    foreach my $sel ( @$list ) {
        if( exists( $YaPI::HTTPDModules::selection{$sel} ) ) {
            push( @ret, @{$YaPI::HTTPDModules::selection{$sel}->{modules}} );
        }
    }
    return @ret;
}

#######################################################
# apache2 modules API end
#######################################################



#######################################################
# apache2 modify service
#######################################################

=item *
C<ModifyService($status)>

with this function you can turn on and off the apache2
runlevel script.
Turning off means, no apache2 start at boot time.

EXAMPLE

 ModifyService(0); # turn apache2 off
 ModifyService(1); # turn apache2 on

=cut

BEGIN { $TYPEINFO{ModifyService} = ["function", "boolean", "boolean" ]; }
sub ModifyService {
    my $self = shift;
    my $enable = shift;

    if( $enable ) {
        Service->Adjust( "apache2", "enable" );
        Service->RunInitScript( "apache2", "restart");
    } else {
        Service->Adjust( "apache2", "disable" );
        Service->RunInitScript( "apache2", "stop" );
    }
    return 1;
}

=item *
C<$status = ReadService()>

with this function you can read out the state of the
apache2 runlevel script (starting apache2 at boot time).

EXAMPLE

 print "apache2 is ".( (ReadService())?('on'):('off') )."\n";

=cut
BEGIN { $TYPEINFO{ReadService} = ["function", "boolean"]; }
sub ReadService {
    my $self = shift;
    return Service->Enabled('apache2');
}

#######################################################
# apache2 modify service end
#######################################################



#######################################################
# apache2 listen ports
#######################################################
# internal only
sub ip2device {
    my $self = shift;
    my %ip2device;
    Progress->off();
    SuSEFirewall->Read();
    NetworkDevices->Read();
    my $devices = NetworkDevices->Locate("BOOTPROTO", "static");
    foreach my $dev ( @$devices ) {
        my $ip = NetworkDevices->GetValue($dev, "IPADDR");
        $ip2device{$ip} = $dev if( $ip );
    }
    Progress->on();
    return \%ip2device;
}

=item *
C<CreateListen( $fromPort, $toPort, $listen, $doFirewall )>

with this function you can configure the addresses and ports
the webserver is listening on. $fromPort and $toPort can have
the same value. $listen must be a network interface of the
host but can be an empty string for 'all' interfaces.
The $doFirewall boolean indicates if the SuSEFirewall2 shall
be configured for the settings.

EXAMPLE

 CreateListen( 80, 80, '127.0.0.1', 0 );   # localhost without firewall setup
 CreateListen( 443, 443, '', 1 );          # HTTPS on all interfaces
 CreateListen( 80, 80, '192.168.0.1', 1 ); # internal+firewall setup

=cut

BEGIN { $TYPEINFO{CreateListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ], "boolean" ] ; }
sub CreateListen {
    my $self = shift;
    my $fromPort = shift;
    my $toPort = shift;
    my $ip = shift; #FIXME: this is a list
    my $doFirewall = shift;

    my @listenEntries = @{$self->GetCurrentListen()};
    my %newEntry;
    $newEntry{ADDRESS} = $ip if ($ip);
    $newEntry{PORT} = ($fromPort eq $toPort)?($fromPort):($fromPort.'-'.$toPort);
    SCR->Write( ".http_server.listen", [ @listenEntries, \%newEntry ] );

    if( $doFirewall ) {
        my $ip2device = $self->ip2device();
        my $if = exists($newEntry{ADDRESS})?$ip2device->{$newEntry{ADDRESS}}:'all';
        SuSEFirewall->AddService( $newEntry{PORT}, "TCP", $if );
    }
    return 1;
}

=item *
C<DeleteListen( $fromPort, $toPort, $listen, $doFirewall )>

with this function you can delete an address and port
the webserver is listening on. $fromPort and $toPort can have
the same value. $listen must be a network interface of the
host but can be an empty string for 'all' interfaces.
The $doFirewall boolean indicates if the SuSEFirewall2 shall
be configured for the settings.

EXAMPLE

 DeleteListen( 80, 80, '127.0.0.1', 0 );   # localhost without firewall setup
 DeleteListen( 443, 443, '', 1 );          # HTTPS on all interfaces
 DeleteListen( 80, 80, '192.168.0.1', 1 ); # internal+firewall setup

=cut

BEGIN { $TYPEINFO{DeleteListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ], 'boolean' ] ; }
sub DeleteListen {
    my $self = shift;
    my $fromPort = shift;
    my $toPort = shift;
    my $ip = shift; #FIXME: this is a list
    my $doFirewall = shift;

    my @listenEntries = @{$self->GetCurrentListen()};
    my @newListenEntries = ();
    foreach my $listen ( @listenEntries ) {
        if( defined($ip) and (not exists($listen->{'ADDRESS'}) or $listen->{'ADDRESS'} ne $ip) ) {
            push( @newListenEntries, $listen );
            next;
        }
        next if( "$fromPort-$toPort" eq $listen->{'PORT'} );
        next if( ($fromPort eq $toPort) and $listen->{'PORT'} eq $fromPort );
        push( @newListenEntries, $listen );
    }
    SCR->Write( ".http_server.listen", \@newListenEntries );
    if( $doFirewall ) {
        my $ip2device = $self->ip2device();
        my $if = $ip?$ip2device->{$ip}:'all';
        my $port = ($fromPort eq $toPort)?($fromPort):("$fromPort-$toPort");
        SuSEFirewall->RemoveService( $port, "TCP", $if );
    }
    return 1;
}

=item *
C<$listenList = GetCurrentListen()>

this function returns a list of hashes with the current listen data.
Each hash has the following keys:

ADDRESS => the listen address like 127.0.0.1

PORT    => the listen port like "80", "443", "80-81"

it is not possible to get the firewall settings.

EXAMPLE

 my $listenList = GetCurrentListen();
 foreach my $ld ( @$listenList ) {
     print "Listening on: ".$ld->{ADDRESS}."/".$ld->{PORT}."\n";
 }

=cut

BEGIN { $TYPEINFO{GetCurrentListen} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetCurrentListen {
    my $self = shift;
    my @data = SCR->Read('.http_server.listen');
    my @ret;
    if( not ref($data[0]) ) {
        return $self->SetError( summary => 'read listen in agent failed' );
    }
    foreach my $listen ( @{$data[0]} ) {
        if( $listen =~ /^([^:]+):([^:]+)/ ) {
            push( @ret, { ADDRESS => $1, PORT => $2 } );
        } elsif( $listen =~ /^\d+$/ ) {
            push( @ret, { PORT => $listen } );
        }
    }
    return \@ret;
}

#######################################################
# apache2 listen ports end
#######################################################



#######################################################
# apache2 pacakges
#######################################################

=item *
C<GetServicePackages()>

???

=cut

BEGIN { $TYPEINFO{GetServicePackages} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetServicePackages {
    my $self = shift;
    return 'apache2'; #???
}

=item *
C<GetModulePackages()>

???

=cut

BEGIN { $TYPEINFO{GetModulePackages} = ["function", ["list", "string"] ]; }
sub GetModulePackages {
    my $self = shift;
    my $mods = $self->GetModuleSelectionsList();
    my %uniq;

    foreach my $mod ( @$mods ) {
        @uniq{@{$mod->{packages}}} = ();
    }
    return keys(%uniq);
}

#######################################################
# apache2 packages end
#######################################################



#######################################################
# apache2 logs
#######################################################

# list<string> GetErrorLogFiles( list<string> );
BEGIN { $TYPEINFO{GetErrorLogFiles} = ["function", ["list", "string" ], [ "list", "string" ] ]; }
sub GetErrorLogFiles {
    my $self = shift;

}

# list<string> GetAccessLogFiles( list<string> );
BEGIN { $TYPEINFO{GetAccessLogFiles} = ["function", ["list", "string" ], [ "list", "string" ] ]; }
sub GetAccessLogFiles {
    my $self = shift;

}

# list<string> GetTransferLogFiles( list<string> );
BEGIN { $TYPEINFO{GetTransferLogFiles} = ["function", ["list", "string"], [ "list", "string" ] ]; }
sub GetTransferLogFiles {
    my $self = shift;

}

#######################################################
# apache2 logs end
#######################################################

#######################################################
# apache2 start parameter
#######################################################

=item *
C<$params = GetServerFlags()>

returns a string with the apache2 server flags like
"-DSSL"

EXAMPLE

  print GetServerFlags();

=cut

sub GetServerFlags {
    my $self = shift;
    return SCR->Read('.sysconfig.apache2.APACHE_SERVER_FLAGS');
}

=item *
C<SetServerFlags($params)>

Put into $params any server flags ("Defines") that you want to hand over to
httpd at start time, or other command line flags.
This could be -D SSL, for example. Or -DSTATUS.

EXAMPLE

  SetServerFlags("-DReverseProxy");

=cut

sub SetServerFlags {
    my $self = shift;
    my $param = shift;

    SCR->Write('.sysconfig.apache2.APACHE_SERVER_FLAGS', $param);
}

#######################################################
# apache2 start parameter end
#######################################################


#######################################################
# apache2 ssl certificates
#######################################################

=item *
C<WriteServerCert($hostId,$pemData)>

this function writes the server certificate for the
host with $hostID to the right place and sets the
SSLCertificateFile directive to the right path.
The certificate must be in PEM format and it can contain
the private key too. If there is a private key in the PEM data,
the SSLCertificateKeyFile directive is set too.
The key can also be set via WriteServerKey.
Writing the server certificate does not turn on SSL
automatically.
On failure, undef is returned.

EXAMPLE

  WriteServerCert('*:443', $pemData);
  $host = GetHost('*:443');
  replaceKey( 'SSL', { KEY => 'SSL', VALUE => 1 }, $host );
  ModifyHost('*:443', $host);

=cut

sub WriteServerCert {
    my $self = shift;
    my $hostid = shift;
    my $pemData = shift;
    my $key = ($pemData =~ /PRIVATE KEY/)?(1):(0);

    if( not $pemData or $pemData !~ /BEGIN CERTIFICATE/ ) {
        return $self->SetError( summary => "corrupt PEM data" );
    }

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => "unable to fetch host with id: $hostid" );
    }
    my $file;
    foreach my $k ( @$host ) {
        next unless( $k->{KEY} eq 'ServerName' );
        $file = $k->{VALUE};
        last;
    }
    $file .= '-cert.pem';
    SCR->Write( '.target.string', $file, $pemData );

    my $found = 0;
    foreach my $k ( @$host ) {
        if( $k->{KEY} eq 'SSLCertificateFile' ) {
            $k->{VALUE} = $file;
            $found += 1;
        } elsif( $key and $k->{KEY} eq 'SSLCertificateKeyFile' ) {
            $k->{VALUE} = $file;
            $found += 2;
        }
    }
    push( @$host, { KEY => 'SSLCertificateFile', VALUE => $file } ) unless( $found & 1 );
    push( @$host, { KEY => 'SSLCertificateKeyFile', VALUE => $file } ) unless( $key and not($found & 2) );
    return $self->ModifyHost( $hostid, $host );
}

=item *
C<WriteServerKey($hostID, $pemData)>

this function writes the server key for the
host with $hostID to the right place and sets the
SSLCertificateKeyFile directive to the right path.
The key must be in PEM format and it can contain
the certificate too. If there is a certificate in the PEM data,
the SSLCertificateFile directive is set too.
The certificate can also be set via WriteServerCert.
Writing the server key does not turn on SSL automatically.
On failure, undef is returned.


EXAMPLE

  WriteServerCert('*:443', $certData);
  WriteServerKey('*:443', $keyData);

=cut


sub WriteServerKey {
    my $self = shift;
    my $hostid = shift;
    my $pemData = shift;
    if( not $pemData or $pemData !~ /PRIVATE KEY/ ) {
        return $self->SetError( summary => "corrupt PEM data" );
    }
    my $cert = ($pemData =~ /BEGIN CERTIFICATE/)?(1):(0);

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => "unable to fetch host with id: $hostid" );
    }
    my $file;
    foreach my $k ( @$host ) {
        next unless( $k->{KEY} eq 'ServerName' );
        $file = $k->{VALUE};
        last;
    }
    $file .= '-key.pem';
    SCR->Write( '.target.string', $file, $pemData );

    my $found = 0;
    foreach my $k ( @$host ) {
        if( $cert and $k->{KEY} eq 'SSLCertificateKeyFile' ) {
            $k->{VALUE} = $file;
            $found += 1;
        } elsif( $k->{KEY} eq 'SSLCertificateKeyFile' ) {
            $found += 2;
        }
    }
    push( @$host, { KEY => 'SSLCertificateKeyFile', VALUE => $file } ) if( $cert and not($found & 1) );
    push( @$host, { KEY => 'SSLCertificateFile', VALUE => $file } ) unless( $found & 2 );
    return $self->ModifyHost( $hostid, $host );
}

=item *
C<WriteServerCA($hostID, $pemData)>

this function writes the server CA for the
host with $hostID to the right place and sets the
SSLCACertificateFile directive to the right path.
The CA must be in PEM format.
Writing the server CA does not turn on SSL automatically.
On failure, undef is returned.

EXAMPLE

  WriteServerCA($hostID, $pemData);

=cut


sub WriteServerCA {
    my $self = shift;
    my $hostid = shift;
    my $pemData = shift;
    if( not $pemData or $pemData !~ /BEGIN CERTIFICATE/ ) {
        return $self->SetError( summary => "corrupt PEM data" );
    }

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => "unable to fetch host with id: $hostid" );
    }
    my $file;
    foreach my $k ( @$host ) {
        next unless( $k->{KEY} eq 'ServerName' );
        $file = $k->{VALUE};
        last;
    }
    $file .= '-cacert.pem';
    my $cert = SCR->Write( '.target.string', $file, $pemData );

    my $found = 0;
    foreach my $k ( @$host ) {
        if( $k->{KEY} eq 'SSLCACertificateFile' ) {
            $k->{VALUE} = $file;
        }
        $found = 1;
        last;
    }
    push( @$host, { KEY => 'SSLCACertificateFile', VALUE => $file } ) if( not $found );
    return $self->ModifyHost( $hostid, $host );
}

=item *
C<$pemData = ReadServerCert($hostID)>

this function returns the server certificate PEM
data. Even if the key is stored in the same file,
just the certificate part is returned.
On failure, undef is returned.

EXAMPLE

  $pemData = ReadServerCert($hostID);
  if( $pemData and open( CERT, "> /tmp/cert.pem" ) ) {
      print CERT $pemData;
      close(CERT);
      $text = `openssl x509 -in /tmp/cert.pem -text -noout`;
  }

=cut

sub ReadServerCert {
    my $self = shift;
    my $hostid = shift;

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => "unable to fetch host with id: $hostid" );
    }
    my $file;
    foreach my $k ( @$host ) {
        next unless( $k->{KEY} eq 'SSLCertificateFile' );
        $file = $k->{VALUE};
        last;
    }
    unless( $file ) {
        return $self->SetError( summary => "no certificate file configured for this hostid" );
    }
    my $cert = SCR->Read( '.target.string', $file );
    unless( $cert ) {
        return $self->SetError( summary => "error reading certificate: $file" );
    }
    $cert =~ /(-----BEGIN CERTIFICATE-----[^-]+-----END CERTIFICATE-----)/;
    if( ! $1 ) {
        return $self->SetError( "parsing cert file failed" );
    }
    return $1;
}

=item *
C<$pemData = ReadServerKey($hostID)>

this function returns the server key in PEM
format. Even if the certificate is stored in the same
file, just the private key part is returned.
On failure, undef is returned.

EXAMPLE

  $cert = ReadServerCert($hostID);
  $key  = ReadServerKey($hostID);

=cut

sub ReadServerKey {
    my $self = shift;
    my $hostid = shift;

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => "unable to fetch host with id: $hostid" );
    }
    my $file;
    foreach my $k ( @$host ) {
        next unless( $k->{KEY} eq 'SSLCertificateKeyFile' );
        $file = $k->{VALUE};
        last;
    }
    unless( $file ) {
        foreach my $k ( @$host ) {
            next unless( $k->{KEY} eq 'SSLCertificateFile' );
            $file = $k->{VALUE};
            last;
        }
        unless( $file ) {
            return $self->SetError( summary => "no certificate key file configured for this hostid" );
        }
    }
    my $cert = SCR->Read( '.target.string', $file );
    unless( $cert ) {
        return $self->SetError( summary => "error reading certificate: $file" );
    }
    $cert =~ /(-----BEGIN RSA PRIVATE KEY-----[^-]+-----END RSA PRIVATE KEY-----)/;
    if( ! $1 ) {
        return $self->SetError( "parsing key file failed" );
    }
    return $1;

}

=item *
C<$pemData = ReadServerCA($hostID)>

this function returns the server CA in PEM
format.
On failure, undef is returned.

EXAMPLE

  $CA =  ReadServerCA($hostID);
  if( $CA ) {
      $fingerprint = `echo "$CA"|openssl x509 -fingerprint -noout`;
  }

=cut

sub ReadServerCA {
    my $self = shift;
    my $hostid = shift;

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => "unable to fetch host with id: $hostid" );
    }
    my $file;
    foreach my $k ( @$host ) {
        next unless( $k->{KEY} eq 'SSLCACertificateFile' );
        $file = $k->{VALUE};
        last;
    }
    unless( $file ) {
        return $self->SetError( summary => "no ca certificate file configured for this hostid" );
    }
    my $cert = SCR->Read( '.target.string', $file );
    unless( $cert ) {
        return $self->SetError( summary => "error reading ca certificate: $file" );
    }
    return $cert;
}

#######################################################
# apache2 ssl certificates end
#######################################################


sub run {
    my $self = __PACKAGE__;
    print "-------------- GetHostsList\n";
    foreach my $h ( @{$self->GetHostsList()} ) {
        print "ID: $h\n";
    }

    print "-------------- ModifyHost Number 0\n";
    my $hostid = "default";
    my @hostArr = @{$self->GetHost( $hostid )};
    $self->ModifyHost( $hostid, \@hostArr );

    print "-------------- CreateHost\n";
    my @temp = (
                { KEY => "ServerName",    VALUE => 'createTest2.suse.de' },
                { KEY => "VirtualByName", VALUE => 1 },
                { KEY => "ServerAdmin",   VALUE => 'no@one.de' }
                );
    $self->CreateHost( '192.168.1.2/createTest2.suse.de', \@temp );

    print "-------------- GetHost created host\n";
    @hostArr = @{$self->GetHost( '*:80/dummy-host.example.com' )};
    use Data::Dumper;
    print Data::Dumper->Dump( [ \@hostArr ] );

    system("cat /etc/apache2/vhosts.d/yast2_vhosts.conf");

    print "-------------- DeleteHost Number 0\n";
    $self->DeleteHost( '192.168.1.2/createTest2.suse.de' );

    print "-------------- show module list\n";
    foreach my $mod ( @{$self->GetModuleList()} ) {
        print "MOD: $mod\n";
    }

    print "-------------- show known modules\n";
    foreach my $mod ( @{$self->GetKnownModules()} ) {
        print "KNOWN MOD: $mod->{name}\n";
    }

    print "-------------- show known selections\n";
    foreach my $mod ( @{$self->GetKnownModuleSelections()} ) {
        print "KNOWN SEL: $mod->{id}\n";
    }

    $self->ModifyModuleList( ['ssl'], 0 );

    print "-------------- show active selections\n";
    $self->GetModuleSelectionsList();

    print "-------------- activate apache2\n";
    $self->ModifyService(1);

    print "-------------- get listen\n";
    foreach my $l ( @{$self->GetCurrentListen()} ) {
        print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
        print $l->{PORT}."\n";
    }

    print "-------------- del listen\n";
    $self->DeleteListen( 443,443,'',1 );
    $self->DeleteListen( 80,80,"12.34.56.78",1 );
    print "-------------- get listen\n";
    foreach my $l ( @{$self->GetCurrentListen()} ) {
        print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
        print $l->{PORT}."\n";
    }

    print "-------------- create listen\n";
    $self->CreateListen( 443,443,'',1 );
    $self->CreateListen( 80,80,"12.34.56.78",1 );

    print "--------------set ModuleSelections\n";
    $self->ModifyModuleSelectionList( [ 'mod_test1', 'mod_test2', 'mod_test3' ], 1 );
    $self->ModifyModuleSelectionList( [ 'mod_test3' ], 0 );

    print "-------------- get ModuleSelections\n";
    foreach my $sel ( @{$self->GetModuleSelectionsList()} ) {
        print "SEL: $sel\n";
    }

    print "--------------trigger error\n";
    my $host = $self->GetHost( 'will.not.be.found' );
    if( not defined $host ) {
        my %error = $self->Error();
        while( my ($k,$v) = each(%error) ) {
            print "ERROR: $k = $v\n";
        }
    }
    print "\n";

}
1;
