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
foreach my $hostid ( HTTPD::GetHostsList() ) {
    $hosts{$hostid} = [ HTTPD::GetHost($hostid) ] if( $hostid );
}

#list<string> GetHostList();
BEGIN { $TYPEINFO{GetHostsList} = ["function", [ "list", "string"] ]; }
sub GetHostsList {
    return keys(%hosts);
}

#map GetHost( string hostid );
BEGIN { $TYPEINFO{GetHost} = ["function", ["list", [ "map", "string", "any" ] ], "string"]; }
sub GetHost {
    my $hostid = shift;
    return @{$hosts{$hostid}};
}

#boolean ModifyHost( string hostid, list hostdata );
BEGIN { $TYPEINFO{ModifyHost} = ["function", "boolean", "string", [ "map", "string", "any" ] ]; }
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
}

# list<map> GetKnownModules()
BEGIN { $TYPEINFO{GetKnownModules} = ["function", [ "list", ["map","string","any"] ] ]; }
sub GetKnownModules {
}

# bool ModifyModuleList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleList} = ["function", "boolean", [ "list","string" ], "boolean" ]; }
sub ModifyModuleList {
}

# map GetKnownModulSelections()
BEGIN { $TYPEINFO{GetKnownModulSelections} = ["function", [ "map","string","any" ] ]; }
sub GetKnownModulSelections {
}

# list<string> GetModuleSelectionsList()
BEGIN { $TYPEINFO{GetModuleSelectionsList} = ["function", ["list","string"] ]; }
sub GetModuleSelectionsList {
}

# bool ModifyModuleSelectionList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleSelectionList} = ["function", "boolean", ["list","string"], "boolean" ]; }
sub ModifyModuleSelectionList {
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
}

#######################################################
# apache2 modify service end
#######################################################



#######################################################
# apache2 listen ports
#######################################################

# boolean CreateListen( int, int, list<string>, boolean )
# boolean CreateListen( int, int, list<string> )
BEGIN { $TYPEINFO{CreateListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ], "boolean" ] ; }
sub CreateListen {
}

# boolean CreateListen( int, int, list<string> )
BEGIN { $TYPEINFO{DeleteListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ], 'boolean' ] ; }
sub DeleteListen {
}

# list<map> GetCurrentListen()
BEGIN { $TYPEINFO{GetCurrentListen} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetCurrentListen {
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
}

# list<string> GetModulePackages
BEGIN { $TYPEINFO{GetModulePackages} = ["function", ["list", "string"] ]; }
sub GetModulePackages {
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
    #foreach my $mod ( GetModuleList() ) {
    #    print "MOD: $mod\n";
    #}

    print "-------------- show known modules\n";
    #foreach my $mod ( GetKnownModules() ) {
    #    print "KNOWN MOD: $mod->{name}\n";
    #}

    print "-------------- show known selections\n";
    #foreach my $mod ( GetKnownModulSelections() ) {
    #    print "KNOWN SEL: $mod->{id}\n";
    #}

    print "-------------- show active selections\n";
    #GetModuleSelectionsList();

    print "-------------- activate apache2\n";
    #ModifyService(1);

    print "-------------- get listen\n";
    #foreach my $l ( GetCurrentListen() ) {
    #    print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
    #    print $l->{PORT}."\n";
    #}

    print "-------------- del listen\n";
    #DeleteListen( 443,443,'',1 );
    #DeleteListen( 80,80,"12.34.56.78",1 );
    print "-------------- get listen\n";
    #foreach my $l ( GetCurrentListen() ) {
    #    print "$l->{ADDRESS}:" if( $l->{ADDRESS} );
    #    print $l->{PORT}."\n";
    #}

    print "-------------- create listen\n";
    #CreateListen( 443,443,'',1 );
    #CreateListen( 80,80,"12.34.56.78",1 );

    print "--------------set ModuleSelections\n";
    #ModifyModuleSelectionList( [ 'mod_test1', 'mod_test2', 'mod_test3' ], 1 );
    #ModifyModuleSelectionList( [ 'mod_test3' ], 0 );

    print "-------------- get ModuleSelections\n";
    #foreach my $sel ( GetModuleSelectionsList() ) {
    #    print "SEL: $sel\n";
    #}

    print "--------------trigger error\n";
    #my @host = GetHost( 'will.not.be.found' );
    #if( @host and not(defined($host[0])) ) {
    #    my %error = Error();
    #    while( my ($k,$v) = each(%error) ) {
    #        print "ERROR: $k = $v\n";
    #    }
    #}
    print "\n";
}
1;
