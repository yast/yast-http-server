package HTTPD;

BEGIN {
    $TYPEINFO{run} = ["function", "void"];
}
use YaST::YCP;
YaST::YCP::Import ("SCR");

our $VERSION="0.01";

use strict;
use Errno qw(ENOENT);


@YaST::Logic::ISA = qw( YaST );

my $vhost_files;
my $scr_result;

if( ref($scr_result) eq 'HASH' ) {
    $vhost_files = $scr_result;
}

sub getFileByHostid {
    my $hostid = shift;

    foreach my $k ( keys(%$vhost_files) ) {
        foreach my $hostHash ( @{$vhost_files->{$k}} ) {
            return $k if( $hostHash->{HOSTID} eq $hostid );
        }
    }
    return undef;
}

#list<string> getHostlist();
sub GetHostlist {
    my @ret = ();
    foreach my $hostList ( values(%$vhost_files) ) {
        foreach my $hostentryHash ( @$hostList ) {
            push( @ret, $hostentryHash->{HOSTID} ) if( $hostentryHash->{HOSTID} );
        }
    }
    return \@ret;
}

#map getHost( string hostid );
sub GetHost {
    my $hostid = shift;

    my $filename = getFileByHostid( $hostid );
    foreach my $hostHash ( @{$vhost_files->{$filename}} ) {
        if( $hostHash->{HOSTID} eq $hostid ) {
            my %ret;
            foreach my $key ( @{$hostHash->{'DATA'}} ) {
                $ret{$key->{KEY}} = $key->{VALUE};
            }
            $ret{'VirtualByName'} = $hostHash->{'VirtualByName'};
            return \%ret;
        }
    }
    return {};
}

#bool ModifyHost( string hostid, map hostdata );
sub ModifyHost {
    my $hostid = shift;
    my $data = shift;

    my $filename = getFileByHostid( $hostid );
    foreach ( @{$vhost_files->{$filename}} ) {
        if( $_->{HOSTID} eq $hostid ) {
            $_->{'DATA'} = [];
            while( my ( $k,$v ) = each(%$data) ) {
                push( @{$_->{'DATA'}}, { OVERHEAD => '', KEY => $k, VALUE => $v } );
            }
            return 1;
        }
    }
    return 0;
}

#bool CreateHost( string hostid, map hostdata );
sub CreateHost {
    my $hostid = shift;
    my $data = shift;

    my $VirtualByName = delete($data->{VirtualByName}) || 0;

    my @arrData = ();
    foreach my $k ( keys(%$data) ) {
        push( @arrData, { OVERHEAD => '', KEY => $k, VALUE => $data->{$k} } );
    }

    $hostid =~ /^([^\/]+)/;
    my $vhost = $1;
    my $entry = {
                 OVERHEAD      => "# YaST generated vhost entry\n",
                 VirtualByName => $VirtualByName,
                 HOSTID        => $hostid,
                 VHOST         => $vhost,
                 DATA          => \@arrData
    };
    if( ref($vhost_files->{'yast2_vhosts.conf'}) eq 'ARRAY' ) {
        push( @{$vhost_files->{'yast2_vhosts.conf'}}, $entry );
    } else {
        $vhost_files->{'yast2_vhosts.conf'} = [ $entry ];
    }
    return 1;
}

#bool DeleteHost( string hostid );
sub DeleteHost {
    my $hostid = shift;

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
    return 1;
}

#bool WriteHost( string hostid );
sub WriteHost {
    my $hostid = shift;

    my $filename = getFileByHostid( $hostid );
    SCR::Write(".httpd.vhosts.setFile.$filename", $vhost_files->{$filename} );
    return 1;
}

sub run {
    my @data = SCR::Read('.httpd.vhosts');
    $vhost_files = $data[0];

    print "-------------- GetHostlist\n";
    foreach my $h ( @{GetHostlist()} ) {
        print "ID: $h\n";
    }
    print "\n";

    print "-------------- GetHost Number 0\n";
    my $hostid = GetHostlist()->[0];
    my $hostHash = GetHost( $hostid );
    foreach my $k ( keys(%$hostHash) ) {
        print "$k = $hostHash->{$k}\n";
    }
    print "\n";

    print "-------------- DeleteHost Number 0\n";
    DeleteHost( $hostid );

    print "-------------- ModifyHost Number 0\n";
    $hostid = GetHostlist()->[0];
    $hostHash = GetHost( $hostid );
    $hostHash->{'ErrorLog'} = '/modified/now/error.log';
    ModifyHost( $hostid, $hostHash );

    print "-------------- CreateHost\n";
    my %temp = ( ServerName => 'createTest.suse.de', VirtualByName => 1, ServerAdmin => 'no@one.de' );
    CreateHost( '192.168.1.1/createTest.suse.de', \%temp );

    print "-------------- GetHostlist\n";
    foreach my $h ( @{GetHostlist()} ) {
        print "ID: $h\n";
    }
    print "\n";

    print "-------------- GetHost Number 0\n";
    $hostid = GetHostlist()->[0];
    $hostHash = GetHost( $hostid );
    foreach my $k ( keys(%$hostHash) ) {
        print "$k = $hostHash->{$k}\n";
    }
    print "\n";

    print "-------------- WriteHost\n";
    WriteHost('192.168.1.1/createTest.suse.de');
}
1;
