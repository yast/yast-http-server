#package YaPI::HTTPD::System;
package HTTPD;
use YaST::YCP;
BEGIN { push( @INC, '/usr/share/YaST2/modules/' ); }
use HTTPDModules;
YaST::YCP::Import ("SCR");
YaST::YCP::Import ("Service");

#######################################################
# temoprary solution start
#######################################################

my %__error = ();

sub SetError {
    %__error = @_;
    @__error{'package','file','line'} = caller();
    return undef;
}

sub Error {
    return %__error;
}

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
    my $hostid = shift;

    foreach my $k ( keys(%$vhost_files) ) {
        foreach my $hostHash ( @{$vhost_files->{$k}} ) {
            return $k if( $hostHash->{HOSTID} eq $hostid );
        }
    }
    return SetError( summary => 'host not found' );
}

# internal only
sub checkHostmap {
    my $host = shift;

    foreach my $entry ( @$host ) {
        if( ($entry->{KEY} eq 'ServerAdmin') and 
            ($entry->{VALUE} !~ /.+\@.+/) ) {
            return SetError( summary => 'illegal ServerAdmin parameter' );
        }
        # more to go
    }
    return 1;
}

#list<string> GetHostList();
BEGIN { $TYPEINFO{GetHostsList} = ["function", [ "list", "string"] ]; }
sub GetHostsList {
    my @ret = ();
    my @data = SCR::Read('.http_server.vhosts');

    if( ref($data[0]) eq 'HASH' ) {
        foreach my $hostList ( values(%{$data[0]}) ) {
            foreach my $hostentryHash ( @$hostList ) {
                push( @ret, $hostentryHash->{HOSTID} ) if( $hostentryHash->{HOSTID} );
            }
        }
    } else {
        return SetError( summary => 'SCR Agent parsing failed' );
    }
    return @ret;
}

#map GetHost( string hostid );
BEGIN { $TYPEINFO{GetHost} = ["function", [ "map", "string", "any" ], "string"]; }
sub GetHost {
    my $hostid = shift;

    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = SCR::Read('.http_server.vhosts');

    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return SetError( summary => 'SCR Agent parsing failed' );
    }

    my $filename = getFileByHostid( $hostid );
    return SetError( summary => 'hostid not found' ) unless( $filename );
    foreach my $hostHash ( @{$vhost_files->{$filename}} ) {
        if( $hostHash->{HOSTID} eq $hostid ) {
            use Data::Dumper;
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
            if( $sslEngine eq 'on' and exists($hostHash->{'DATA'}->{'SSLRequireSSL'}) ) {
                delete($hostHash->{'DATA'}->{'SSLRequireSSL'});
                $sslHash->{'VALUE'} = 2;
            } elsif( $sslEngine eq 'on' ) {
                $sslHash->{'VALUE'} = 1;
            }
            return ( @{$hostHash->{'DATA'}}, $sslHash, $vbnHash );
        }
    }
    return SetError( summary => 'hostid not found' );
}

#boolean ModifyHost( string hostid, list hostdata );
BEGIN { $TYPEINFO{ModifyHost} = ["function", "boolean", "string", [ "map", "string", "any" ] ]; }
sub ModifyHost {
    my $hostid = shift;
    my $newData = shift;

    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = SCR::Read('.http_server.vhosts');
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return SetError( summary => 'SCR Agent parsing failed' );
    }

    my $filename = getFileByHostid( $hostid );
    return undef if( not checkHostmap( $newData ) );
    foreach my $entry ( @{$vhost_files->{$filename}} ) {
        if( $entry->{HOSTID} eq $hostid ) {
            $entry->{DATA} = $newData;
            writeHost( $filename );
            return 1;
        }
    }
    return 0; # host not found. Error?
}

#bool CreateHost( string hostid, list hostdata );
BEGIN { $TYPEINFO{CreateHost} = ["function", "boolean", "string", [ "map", "string", "any" ] ]; }
sub CreateHost {
    my $hostid = shift;
    my $data = shift;

    my $sslHash = { KEY => 'SSLEngine' , VALUE => 'off' };
    my @tmp = ( $sslHash );
    my $VirtualByName = 0;
    foreach my $key ( @$data ) {
        # VirtualByName and SSL get dropped/replaced
        if( $key->{KEY} eq 'VirtualByName' ) {
            $VirtualByName = $key->{VALUE};
        } elsif( $key->{KEY} eq 'SSL' and $key->{VALUE} == 1 ) {
            $sslHash->{'VALUE'} = 'on';
        } elsif( $key->{KEY} eq 'SSL' and $key->{VALUE} == 2 ) {
            $sslHash->{'VALUE'} = 'on';
            push( @tmp, { KEY => 'SSLRequireSSL', VALUE => '' } );
        } else {
            push( @tmp, $key );
        }
    }
    $data = \@tmp;
    return undef if( not checkHostmap( $data ) );

    $hostid =~ /^([^\/]+)/;
    my $vhost = $1;
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
    my @data = SCR::Read('.http_server.vhosts');
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return SetError( summary => 'SCR Agent parsing failed' );
    }
    if( ref($vhost_files->{'yast2_vhosts.conf'}) eq 'ARRAY' ) {
        # merge new entry with existing entries in yast2_vhosts.conf
        push( @{$vhost_files->{'yast2_vhosts.conf'}}, $entry );
    } else {
        # create new yast2_vhosts.conf
        $vhost_files->{'yast2_vhosts.conf'} = [ $entry ];
    }
    writeHost( 'yast2_vhosts.conf' );
    return 1;
}

#bool DeleteHost( string hostid );
BEGIN { $TYPEINFO{DeleteHost} = ["function", "boolean", "string"]; }
sub DeleteHost {
    my $hostid = shift;

    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = SCR::Read('.http_server.vhosts');
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return SetError( summary => 'SCR Agent parsing failed' );
    }
    my $filename = getFileByHostid( $hostid );
    my @newList = ();
    foreach my $hostHash ( @{$vhost_files->{$filename}} ) {
        push( @newList, $hostHash ) if( $hostHash->{HOSTID} ne $hostid );
    }
    if( @newList ) {
        $vhost_files->{$filename} = \@newList;
    } else {
        delete($vhost_files->{$filename}); # drop empty file
    }
    writeHost( $filename );
    return 1;
}

# internal only!
sub writeHost {
    my $filename = shift;

    SCR::Write(".http_server.vhosts.setFile.$filename", $vhost_files->{$filename} );
    return 1;
}

#######################################################
# default and vhost API end
#######################################################


#######################################################
# apache2 modules API start
#######################################################

# list<string> GetModuleList()
BEGIN { $TYPEINFO{GetModuleList} = ["function", [ "list", "string" ] ]; }
sub GetModuleList {
    my $data = SCR::Read('.sysconfig.apache2.APACHE_MODULES'); # FIXME: Error handling
    $data =~ s/mod_//g;

    return split(/\s+/, $data);
}

# list<map> GetKnownModules()
BEGIN { $TYPEINFO{GetKnownModules} = ["function", [ "list", ["map","string","any"] ] ]; }
sub GetKnownModules {
    my @ret = ();
    foreach my $mod ( keys(%HTTPDModules::modules) ) {
        push( @ret, { name => $mod, %{$HTTPDModules::modules{$mod}} } );
    }
    return @ret;
}

# bool ModifyModuleList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleList} = ["function", "boolean", [ "list","string" ], "boolean" ]; }
sub ModifyModuleList {
    my $newModules = shift;
    my $enable = shift;
    my %uniq = ();

    @uniq{GetModuleList()} = ();
    if( $enable ) {
        @uniq{@$newModules} = ();
    } else {
        delete(@uniq{@$newModules});
    }

    SCR::Write('.sysconfig.apache2.APACHE_MODULES', [ join(' ',keys(%uniq)) ]);
    return 1;
}

# map GetKnownModulSelections()
BEGIN { $TYPEINFO{GetKnownModulSelections} = ["function", [ "map","string","any" ] ]; }
sub GetKnownModulSelections {
    my @ret = ();
    foreach my $sel ( keys(%HTTPDModules::selection) ) {
        push( @ret, { id => $sel, %{$HTTPDModules::selection{$sel}} } );
    }
    return @ret;
}

# list<string> GetModuleSelectionsList()
BEGIN { $TYPEINFO{GetModuleSelectionsList} = ["function", ["list","string"] ]; }
sub GetModuleSelectionsList {
    return @{(SCR::Read('.http_server.moduleselection'))[0]};
}

# bool ModifyModuleSelectionList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleSelectionList} = ["function", "boolean", ["list","string"], "boolean" ]; }
sub ModifyModuleSelectionList {
    my $newSelection = shift;
    my $enable = shift;
    my %uniq = ();

    @uniq{GetModuleSelectionsList()} = ();
    if( $enable ) {
        @uniq{@$newSelection} = ();
    } else {
        delete(@uniq{@$newSelection});
    }

    SCR::Write('.http_server.moduleselection', [keys(%uniq)]);
}

#######################################################
# apache2 modules API end
#######################################################



#######################################################
# apache2 modify service
#######################################################

# boolean ModiflyService( boolean )
BEGIN { $TYPEINFO{ModifyService} = ["function", "boolean", "boolean" ]; }
sub ModifyService {
    my $enable = shift;

    if( $enable ) {
        Service::Adjust( "apache2", "enable" );
        Service::RunInitScript( "apache2", "restart");
    } else {
        Service::Adjust( "apache2", "disable" );
        Service::RunInitScript( "apache2", "stop" );
    }
    return 1;
}

#######################################################
# apache2 modify service end
#######################################################



#######################################################
# apache2 listen ports
#######################################################
# boolean CreateListen( int, int, list<string> )
BEGIN { $TYPEINFO{CreateListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ] ] ; }
sub CreateListen {
    my $fromPort = shift;
    my $toPort = shift;
    my $ip = shift; #FIXME: this is a list

    my @listenEntries = GetCurrentListen();
    my %newEntry;
    $newEntry{ADDRESS} = $ip if ($ip);
    $newEntry{PORT} = ($fromPort eq $toPort)?($fromPort):($fromPort.'-'.$toPort);
    SCR::Write( ".http_server.listen", [ @listenEntries, \%newEntry ] );
}

# boolean CreateListen( int, int, list<string> )
BEGIN { $TYPEINFO{DeleteListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ] ] ; }
sub DeleteListen {
    my $fromPort = shift;
    my $toPort = shift;
    my $ip = shift; #FIXME: this is a list

    my @listenEntries = GetCurrentListen();
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
    SCR::Write( ".http_server.listen", \@newListenEntries );
    return 1;
}

# list<map> GetCurrentListen()
BEGIN { $TYPEINFO{GetCurrentListen} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetCurrentListen {
    my @data = SCR::Read('.http_server.listen');
    my @ret;
    foreach my $listen ( @data ) {
        if( $listen =~ /^([^:]+):([^:]+)/ ) {
            push( @ret, { ADDRESS => $1, PORT => $2 } );
        } elsif( $listen =~ /^\d+$/ ) {
            push( @ret, { PORT => $listen } );
        }
    }
    return @ret;
}

#######################################################
# apache2 listen ports end
#######################################################



#######################################################
# apache2 pacakges
#######################################################

# list<string> GetServicePackages();
BEGIN { $TYPEINFO{GetServicePackages} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetServicePackages {
    return 'apache2'; #???
}

# list<string> GetModulePackages
BEGIN { $TYPEINFO{GetModulePackages} = ["function", ["list", "string"] ]; }
sub GetModulePackages {
    my $mods = GetModuleSelectionsList();
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
# apache2 firewall
#######################################################

#######################################################
# apache2 firewall end
#######################################################



sub run {
    print "-------------- GetHostsList\n";
    foreach my $h ( GetHostsList() ) {
        print "ID: $h\n";
    }

    print "-------------- ModifyHost Number 0\n";
    my $hostid = "default";
    my @hostArr = GetHost( $hostid );
    ModifyHost( $hostid, \@hostArr );

    print "-------------- CreateHost\n";
    my @temp = (
                { KEY => "ServerName",    VALUE => 'createTest2.suse.de' },
                { KEY => "VirtualByName", VALUE => 1 },
                { KEY => "ServerAdmin",   VALUE => 'no@one.de' }
                );
    CreateHost( '192.168.1.2/createTest2.suse.de', \@temp );

    print "-------------- GetHost created host\n";
    @hostArr = GetHost( '192.168.1.2/createTest2.suse.de' );
    use Data::Dumper;
    print Data::Dumper->Dump( [ \@hostArr ] );

    system("cat /etc/apache2/vhosts.d/yast2_vhosts.conf");

    print "-------------- DeleteHost Number 0\n";
    DeleteHost( '192.168.1.2/createTest2.suse.de' );

    print "-------------- show module list\n";
    foreach my $mod ( GetModuleList() ) {
        print "MOD: $mod\n";
    }

    print "-------------- show known modules\n";
    foreach my $mod ( GetKnownModules() ) {
        print "KNOWN MOD: $mod->{name}\n";
    }

    print "-------------- show known selections\n";
    foreach my $mod ( GetKnownModulSelections() ) {
        print "KNOWN SEL: $mod->{id}\n";
    }

    print "-------------- show active selections\n";
    GetModuleSelectionsList();

    print "-------------- activate apache2\n";
    ModifyService(1);

    print "-------------- get listen\n";
    foreach my $l ( GetCurrentListen() ) {
        print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
        print $l->{PORT}."\n";
    }

    print "-------------- del listen\n";
    DeleteListen( 443,443 );
    DeleteListen( 80,80,"12.34.56.78" );
    print "-------------- get listen\n";
    foreach my $l ( GetCurrentListen() ) {
        print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
        print $l->{PORT}."\n";
    }

    print "-------------- create listen\n";
    CreateListen( 443,443 );
    CreateListen( 80,80,"12.34.56.78" );

    print "--------------set ModuleSelections\n";
    ModifyModuleSelectionList( [ 'mod_test1', 'mod_test2', 'mod_test3' ], 1 );
    ModifyModuleSelectionList( [ 'mod_test3' ], 0 );

    print "-------------- get ModuleSelections\n";
    foreach my $sel ( GetModuleSelectionsList() ) {
        print "SEL: $sel\n";
    }



    print "--------------trigger error\n";
    my @host = GetHost( 'will.not.be.found' );
    if( @host and not(defined($host[0])) ) {
        my %error = Error();
        while( my ($k,$v) = each(%error) ) {
            print "ERROR: $k = $v\n";
        }
    }
    print "\n";

}
1;
