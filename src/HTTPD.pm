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
BEGIN { $TYPEINFO{GetHostList} = ["function", [ "list", "string"] ]; }
sub GetHostList {
    my @ret = ();
    my @data = SCR::Read('.httpd.vhosts');

    if( ref($data[0]) eq 'HASH' ) {
        foreach my $hostList ( values(%{$data[0]}) ) {
            foreach my $hostentryHash ( @$hostList ) {
                push( @ret, $hostentryHash->{HOSTID} ) if( $hostentryHash->{HOSTID} );
            }
        }
    } else {
        return SetError( summary => 'SCR Agent parsing failed' );
    }
    return \@ret;
}

#map GetHost( string hostid );
BEGIN { $TYPEINFO{GetHost} = ["function", [ "map", "string", "any" ], "string"]; }
sub GetHost {
    my $hostid = shift;

    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = SCR::Read('.httpd.vhosts');

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
            return [ @{$hostHash->{'DATA'}}, $sslHash, $vbnHash ];
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
    my @data = SCR::Read('.httpd.vhosts');
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
    my @data = SCR::Read('.httpd.vhosts');
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
    my @data = SCR::Read('.httpd.vhosts');
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

    SCR::Write(".httpd.vhosts.setFile.$filename", $vhost_files->{$filename} );
    return 1;
}

#######################################################
# default and vhost API end
#######################################################


#######################################################
# apache2 modules API start
#######################################################

# list<string> GetModuleList()
sub GetModuleList {
    my $data = SCR::Read('.sysconfig.apache2.APACHE_MODULES'); # FIXME: Error handling
    $data =~ s/mod_//g;

    return [ split(/\s+/, $data) ];
}

# list<map> GetKnownModules()
sub GetKnownModules {
    my @ret = ();
    foreach my $mod ( keys(%HTTPDModules::modules) ) {
        push( @ret, { name => $mod, %{$HTTPDModules::modules{$mod}} } );
    }
    return \@ret;
}

# bool ModifyModuleList( list<string>, bool )
sub ModifyModuleList {
    my $list = shift;

    SCR::Write('.sysconfig.apache2.APACHE_MODULES', [ join(' ',@$list) ] ); #FIXME: Error handling
    return 1;
}

# map GetKnownModulSelections()
sub GetKnownModulSelections {
    my @ret = ();
    foreach my $sel ( keys(%HTTPDModules::selection) ) {
        push( @ret, { id => $sel, %{$HTTPDModules::selection{$sel}} } );
    }
    return \@ret;
}

# list<string> GetModuleSelectionsList()
sub GetModuleSelectionsList {
    my $activeModules = GetModuleList();
    my $knowSelections = GetKnownModulSelections();
    my @ret;

    foreach my $selection ( @$knowSelections ) {
        my $active = 1;
        foreach my $selMod ( @{$selection->{'modules'}} ) {
            unless( grep( { $selMod eq $_ } @$activeModules ) ) {
                $active = 0;
                last;
            }
        }
        push( @ret, $selection->{id} ) if( $active );
    }
    return \@ret;
}

# bool ModifyModuleSelectionList( list<string>, bool )
sub ModifyModuleSelectionList {
    my $list = shift;
    my $enable = shift;
    my $activeMods = GetModuleList();
    my %modCounter = ();

    foreach my $mod ( @$activeMods ) {
        $modCounter{$mod} = 1;
    }

    foreach my $workSel ( @$list ) {
        if( $enable ) {
            foreach my $mod ( @{$HTTPDModules::selection{$workSel}->{modules}} ) {
                $modCounter{$mod} = 1;
            }
        } else {

        }
    }
    ModifyModuleList( [ keys(%modCounter) ] );
}

#######################################################
# apache2 modules API end
#######################################################



#######################################################
# apache2 modify service
#######################################################

sub ModifyService {
    my $enable = shift;

    if( $enable ) {
        Service::Adjust( "apache2", "enable" );
        Service::RunInitScript( "apache2", "restart");
    } else {
        Service::Adjust( "apache2", "disable" );
        Service::RunInitScript( "apache2", "stop" );
    }
}

#######################################################
# apache2 modify service end
#######################################################


sub run {
    print "-------------- GetHostList\n";
    foreach my $h ( @{GetHostList()} ) {
        print "ID: $h\n";
    }

    print "-------------- ModifyHost Number 0\n";
    my $hostid = "default";
    my $hostArr = GetHost( $hostid );
    ModifyHost( $hostid, $hostArr );

    print "-------------- CreateHost\n";
    my @temp = (
                { KEY => "ServerName",    VALUE => 'createTest.suse.de' },
                { KEY => "VirtualByName", VALUE => 1 },
                { KEY => "ServerAdmin",   VALUE => 'no@one.de' }
                );
    CreateHost( '192.168.1.2/createTest2.suse.de', \@temp );

    print "-------------- GetHost created host \n";
    $hostArr = GetHost( '192.168.1.2/createTest2.suse.de' );
    use Data::Dumper;
    print Data::Dumper->Dump( [ $hostArr ] );

    system("cat /etc/apache2/vhosts.d/yast2_vhosts.conf");

    print "-------------- DeleteHost Number 0\n";
    DeleteHost( '192.168.1.2/createTest2.suse.de' );

    print "-------------- show module list\n";
    foreach my $mod ( @{GetModuleList()} ) {
        print "MOD: $mod\n";
    }

    print "-------------- show known modules\n";
    foreach my $mod ( @{GetKnownModules()} ) {
        print "KNOWN MOD: $mod->{name}\n";
    }

    print "-------------- show known modules\n";
    foreach my $mod ( @{GetKnownModulSelections()} ) {
        print "KNOWN SEL: $mod->{id}\n";
    }

    print "-------------- activate apache2";
    ModifyService(1);

    print "--------------trigger error\n";
    $hostid = GetHost( 'will.not.be.found' );
    unless( $hostid ) {
        my %error = Error();
        while( my ($k,$v) = each(%error) ) {
            print "ERROR: $k = $v\n";
        }
    }
    print "\n";

}
1;
