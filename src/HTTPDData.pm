package HTTPDData;
use YaST::YCP;
BEGIN { push( @INC, '/usr/share/YaST2/modules/' ); }
use HTTPDModules;
use HTTPD;

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

my %hosts;
my %dirty = ( NEW => {}, DEL => {}, MODIFIED => {} );

#bool ReadHosts();
BEGIN { $TYPEINFO{ReadHosts} = ["function", "boolean" ]; }
sub ReadHosts {
    foreach my $hostid ( HTTPD::GetHostsList() ) {
	$hosts{$hostid} = [ HTTPD::GetHost($hostid) ] if( $hostid );
    }
    return 1;
}

my @oldListen = ();
my %newListen = ();
my %delListen = ();

#bool ReadListen();
BEGIN { $TYPEINFO{ReadListen} = ["function", "boolean" ]; }
sub ReadListen {
    @oldListen = HTTPD::GetCurrentListen();
    return 1;
}


my @oldModuleSelections = ();
my %newModuleSelections = ();
my %delModuleSelections = ();

my @oldModules = ();
my %newModules = ();
my %delModules = ();

#bool ReadModules();
BEGIN { $TYPEINFO{ReadModules} = ["function", "boolean" ]; }
sub ReadModules {
    @oldModuleSelections = HTTPD::GetModuleSelectionsList();
    @oldModules = HTTPD::GetModuleList();
    foreach my $mod ( HTTPD::selections2modules([@oldModuleSelections]) ) {
	push(@oldModules, $mod) unless( grep/^$mod$/, @oldModules );
    }
    return 1;
}

my $serviceState;   # 1 = enable, 0=disable

#list<string> GetHostList();
BEGIN { $TYPEINFO{GetHostsList} = ["function", [ "list", "string"] ]; }
sub GetHostsList {
    return keys(%hosts);
}

#map GetHost( string hostid );
BEGIN { $TYPEINFO{GetHost} = ["function", ["list", [ "map", "string", "any" ] ], "string"]; }
sub GetHost {
    my $hostid = shift;
    return exists($hosts{$hostid})?(@{$hosts{$hostid}}):();
}

#boolean ModifyHost( string hostid, list hostdata );
BEGIN { $TYPEINFO{ModifyHost} = ["function", "boolean", "string", ["list", [ "map", "string", "any" ] ] ]; }
sub ModifyHost {
    my $hostid = shift;
    my $hostdata = shift;

    $hosts{$hostid} = $hostdata;
    $dirty{MODIFIED}->{$hostid} = 1 unless( exists($dirty{NEW}->{$hostid}) );
    return 1;
}

#bool CreateHost( string hostid, list hostdata );
BEGIN { $TYPEINFO{CreateHost} = ["function", "boolean", "string", [ "map", "string", "any" ] ]; }
sub CreateHost {
    my $hostid = shift;
    my $hostdata = shift;

    $hosts{$hostid} = $hostdata;
    $dirty{NEW}->{$hostid} = 1;
    delete($dirty{DEL}->{$hostid});
    delete($dirty{MODIFIED}->{$hostid});
    return 1;
}

#bool DeleteHost( string hostid );
BEGIN { $TYPEINFO{DeleteHost} = ["function", "boolean", "string"]; }
sub DeleteHost {
    my $hostid = shift;
    delete( $hosts{$hostid} );
    $dirty{DEL}->{$hostid} = 1 unless( exists( $dirty{NEW}->{$hostid} ) );
    delete($dirty{NEW}->{$hostid});
    delete($dirty{MODIFIED}->{$hostid});
    return 1;
}

sub WriteHosts {
    foreach my $hostid( keys( %{$dirty{DEL}} ) ) {
        HTTPD::DeleteHost( $hostid );
    }
    foreach my $hostid( keys( %{$dirty{NEW}} ) ) {
        HTTPD::CreateHost( $hostid, $hosts{$hostid} );
    }
    foreach my $hostid( keys( %{$dirty{MODIFIED}} ) ) {
        HTTPD::ModifyHost( $hostid, $hosts{$hostid} );
    }
    %dirty = ( NEW => {}, DEL => {}, MODIFIED => {} );
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
    my @ret;
    foreach my $mod ( sort( @oldModules, keys(%newModules) ) ) {
        push( @ret, $mod ) unless( exists( $delModules{$mod} ) );
    }
    return @ret;
}

# list<map> GetKnownModules()
BEGIN { $TYPEINFO{GetKnownModules} = ["function", [ "list", ["map","string","any"] ] ]; }
sub GetKnownModules {
    # no state anyway, so we call the stateless API directly
    return HTTPD::GetKnownModules(); 
}

# bool ModifyModuleList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleList} = ["function", "boolean", [ "list","string" ], "boolean" ]; }
sub ModifyModuleList {
    my $newModules = shift;
    my $enable = shift;

    foreach my $mod ( @$newModules ) {
        if( not $enable ) {
            $delModules{$mod} = 1;
            delete($newModules{$mod});
        } else {
            $newModules{$mod} = 1 unless( grep( /^$mod$/, @oldModules ) );
            delete($delModules{$mod});
        }
    }

    return 1;
}
BEGIN { $TYPEINFO{WriteModuleList} = ["function", "boolean"]; }
sub WriteModuleList {
    HTTPD::ModifyModuleList( [ keys(%delModules) ], 0 );
    HTTPD::ModifyModuleList( [ keys(%newModules) ], 1 );
    %delModules = ();
    %newModules = ();
    @oldModules = HTTPD::GetModuleList();
    return 1;
}

# map GetKnownModulSelections()
BEGIN { $TYPEINFO{GetKnownModulSelections} = ["function", [ "map","string","any" ] ]; }
sub GetKnownModulSelections {
    return HTTPD::GetKnownModulSelections();
}

# list<string> GetModuleSelectionsList()
BEGIN { $TYPEINFO{GetModuleSelectionsList} = ["function", ["list","string"] ]; }
sub GetModuleSelectionsList {
    my @ret;
    foreach my $mod ( sort( @oldModuleSelections, keys(%newModuleSelections) ) ) {
        push( @ret, $mod ) unless( exists( $delModuleSelections{$mod} ) );
    }
    return @ret;
}

# bool ModifyModuleSelectionList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleSelectionList} = ["function", "boolean", ["list","string"], "boolean" ]; }
sub ModifyModuleSelectionList {
    my $newModules = shift;
    my $enable = shift;

    my @mods2sel = HTTPD::selections2modules($newModules);
    if( not $enable ) {
        delete(@newModules{@mods2sel});
        @delModules{@mods2sel} = ();
    } else {
        delete(@delModules{@mods2sel});
        @newModules{@mods2sel} = ();
    }

    foreach my $mod ( @$newModules ) {
        if( not $enable ) {
            $delModuleSelections{$mod} = 1;
            delete($newModuleSelections{$mod});
        } else {
            $newModuleSelections{$mod} = 1 unless( grep( /^$mod$/, @oldModuleSelections ) );
            delete($delModuleSelections{$mod});
        }
    }
    return 1;
}

sub WriteModuleSelectionList {
    HTTPD::ModifyModuleSelectionList( [ keys(%delModuleSelections) ], 0 );
    HTTPD::ModifyModuleSelectionList( [ keys(%newModuleSelections) ], 1 );
    %newModuleSelections = ();
    %delModuleSelections = ();
    @oldModuleSelections = HTTPD::GetModuleSelectionsList();
    return 1;
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
    $serviceState = shift;
    return 1;
}

BEGIN { $TYPEINFO{WriteService} = ["function", "boolean", "boolean" ]; }
sub WriteService {
    HTTPD::ModifyService( $serviceState );
}

#######################################################
# apache2 modify service end
#######################################################



#######################################################
# apache2 listen ports
#######################################################

# boolean CreateListen( int, int, list<string>, boolean )
# boolean CreateListen( int, int, list<string> )
BEGIN { $TYPEINFO{CreateListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ] ] ; }
sub CreateListen {
    my $fromPort = shift;
    my $toPort = shift;
    my $ip = shift || ''; #FIXME: this is a list

    my $port = ($fromPort eq $toPort)?($fromPort):($fromPort.'-'.$toPort);
    delete($delListen{"$ip:$fromPort:$toPort"});

    foreach my $old ( @oldListen ) {
        if( ($ip and exists($old->{ADDRESS}) and $ip eq $old->{ADDRESS}) and
            ($port eq $old->{PORT}) ) {
            return 1; # already created listen
        } elsif( not($ip) and not(exists($old->{ADDRESS})) and
                 $port eq $old->{PORT} ) {
            return 1; # already created listen
        }
    }

    $newListen{"$ip:$fromPort:$toPort"} = 1;

    return 1;
}

# boolean CreateListen( int, int, list<string> )
BEGIN { $TYPEINFO{DeleteListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ] ] ; }
sub DeleteListen {
    my $fromPort = shift;
    my $toPort = shift;
    my $ip = shift; #FIXME: this is a list

    $delListen{"$ip:$fromPort:$toPort"} = 1;
    delete($newListen{"$ip:$fromPort:$toPort"});

    return 1;
}

# list<map> GetCurrentListen()
BEGIN { $TYPEINFO{GetCurrentListen} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetCurrentListen {
    my @new;
    foreach my $new ( keys(%newListen) ) {
        my ( $ip, $fp, $tp ) = split(/:/, $new);
        my $port = ($fp eq $tp)?($fp):($fp.'-'.$tp);
        push( @new, { ADDRESS => $ip, PORT => $port } );
    }
    foreach my $old ( @oldListen ) {
        if( $old->{PORT} =~ /-/ ) {
            my ( $fp, $tp ) = split( /-/, $old->{PORT} );
            my $addr = $old->{ADDRESS} || '';
            next if( exists( $delListen{"$addr:$fp:$tp"} ) );
        } else {
            my $addr = $old->{ADDRESS} || '';
            next if( exists( $delListen{"$addr:$old->{PORT}:$old->{PORT}"} ) );
        }
        push( @new, $old );
    }
    return @new;
}

sub WriteListen {
    my $doFirewall = shift;

    foreach my $toDel ( keys(%delListen) ) {
        my ($ip,$fp,$tp) = split(/:/, $toDel);
        HTTPD::DeleteListen( $fp, $tp, $ip, $doFirewall );
    }
    foreach my $toCreate ( keys(%newListen) ) {
        my ($ip,$fp,$tp) = split(/:/, $toCreate);
        HTTPD::CreateListen( $fp, $tp, $ip, $doFirewall );
    }
    %delListen = ();
    %newListen = ();
    @oldListen = HTTPD::GetCurrentListen();
}

#######################################################
# apache2 listen ports end
#######################################################



#######################################################
# apache2 packages
#######################################################

# list<string> GetServicePackages();
BEGIN { $TYPEINFO{GetServicePackages} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetServicePackages {
    return HTTP::GetServicePackages(); # no state here anyway
}

# list<string> GetModulePackages
BEGIN { $TYPEINFO{GetModulePackages} = ["function", ["list", "string"] ]; }
sub GetModulePackages {
    my @ret;
    foreach my $mod ( GetModuleList() ) {
        if( exists($HTTPDModules::modules{$mod}) ) {
            push( @ret, @{$HTTPDModules::modules{$mod}->{packages}} );
        }
    }
    return @ret;
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

}

# list<string> GetAccessLogFiles( list<string> );
BEGIN { $TYPEINFO{GetAccessLogFiles} = ["function", ["list", "string" ], [ "list", "string" ] ]; }
sub GetAccessLogFiles {

}

# list<string> GetTransferLogFiles( list<string> );
BEGIN { $TYPEINFO{GetTransferLogFiles} = ["function", ["list", "string"], [ "list", "string" ] ]; }
sub GetTransferLogFiles {

}

#######################################################
# apache2 logs end
#######################################################

sub run {
    print "-------------- ReadHosts\n";
    ReadHosts();

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
    WriteHosts();

    system("cat /etc/apache2/vhosts.d/yast2_vhosts.conf");

    print "-------------- DeleteHost Number 0\n";
    DeleteHost( '192.168.1.2/createTest2.suse.de' );

    WriteHosts();

    print "-------------- show module list\n";
    foreach my $mod ( GetModuleList() ) {
        print "MOD: $mod\n";
    }

    print "-------------- show known modules\n";
    foreach my $mod ( GetKnownModules() ) {
        print "KNOWN MOD: $mod->{name}\n";
    }

    print "-------------- modify module list\n";
    ModifyModuleList( [ 'cgi' ], 0 );
    ModifyModuleList( [ 'unknownModule' ], 1 );

    print "-------------- show module list\n";
    foreach my $mod ( GetModuleList() ) {
        print "MOD: $mod\n";
    }

#    ModifyModuleList( [ 'cgi' ], 1 );
    WriteModuleList();

    print "-------------- show known selections\n";
    foreach my $mod ( GetKnownModulSelections() ) {
        print "KNOWN SEL: $mod->{id}\n";
    }

    print "-------------- show active selections\n";
    foreach my $sel ( GetModuleSelectionsList() ) {
        print "ACTIVE SEL: $sel\n";
    }

    print "-------------- show module list\n";
    foreach my $mod ( GetModuleList() ) {
        print "MOD: $mod\n";
    }

    print "-------------- modify active selections\n";
    ModifyModuleSelectionList( [ 'TestSel' ], 0 );

    print "-------------- show active selections\n";
    foreach my $sel ( GetModuleSelectionsList() ) {
        print "ACTIVE SEL: $sel\n";
    }

    print "-------------- show module list\n";
    foreach my $mod ( GetModuleList() ) {
        print "MOD: $mod\n";
    }


    ModifyModuleSelectionList( [ 'TestSel' ], 1 );


    print "-------------- activate apache2\n";
    ModifyService(1);

    print "-------------- get listen\n";
    foreach my $l ( GetCurrentListen() ) {
        print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
        print $l->{PORT}."\n";
    }

    print "-------------- del listen\n";
    DeleteListen( 443,443,'' );
    DeleteListen( 80,80,"12.34.56.78" );
    print "-------------- get listen\n";
    foreach my $l ( GetCurrentListen() ) {
        print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
        print $l->{PORT}."\n";
    }

    print "-------------- create listen\n";
    CreateListen( 443,443,'' );
    CreateListen( 80,80,"12.34.56.78" );

    print "-------------- get listen\n";
    foreach my $l ( GetCurrentListen() ) {
        print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
        print $l->{PORT}."\n";
    }


    print "--------------set ModuleSelections\n";
    #ModifyModuleSelectionList( [ 'mod_test1', 'mod_test2', 'mod_test3' ], 1 );
    #ModifyModuleSelectionList( [ 'mod_test3' ], 0 );

    print "-------------- get ModuleSelections\n";
    #foreach my $sel ( GetModuleSelectionsList() ) {
    #    print "SEL: $sel\n";
    #}

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
