#!/usr/bin/perl -w
package ag_httpd_vhosts;
use ycp;
use YaST::SCRAgent;
our @ISA = ("YaST::SCRAgent");

use strict;

# $vhost_files{$filename} = [ 
#                            {
#                              OVERHEAD => '# ...',
#                              VHOST    => '*',
#                              HOSTID   => '*:443/myservername.my.dom',
#                              VirtualByName => 1,
#                              DATA     => [
#                                           {
#                                            OVERHEAD => '...',
#                                            KEY => 'DocumentRoot',
#                                            VALUE => '/srv/...'
#                                           }
#                                          ]
#                            }
#                           ];

my %vhost_files = ();

# %vhost_by_name is just a uniq array
my %vhost_by_name = ();

parse_files();

sub parse_files {
    my $class = shift;

    if( open( FILE, "< /etc/apache2/listen.conf" ) ) {
        while( my $line = <FILE> ) {
            next unless( $line =~ /^NameVirtualHost\s+(.*)/ );
            my $vhost = $1;
            chomp($vhost);
            $vhost_by_name{$vhost} = 1;
        }
        close(FILE);
    }

    for my $file ( </etc/apache2/vhosts.d/*.conf> ) {
        open( FILE, "< $file" ) or do {
            y2error("unable to open file $file for reading.$!");
            return 0;
        };
        $vhost_files{$file} = [];
        my $entry = {};
        while( my $line = <FILE> ) {
            if( $line =~ /^\s*<VirtualHost\s*([^\s>]+)\s*>/ ) {
                $entry->{VHOST} = $1;
                $entry->{VirtualByName} = 0;
                if( grep( /^$entry->{VHOST}$/, keys(%vhost_by_name) ) ) {
                    $entry->{VirtualByName} = 1;
                }
                push( @{$vhost_files{$file}}, $entry );
                my $data = [];
                my $option = {};
                my $tmpServerName = '';
                while( my $line = <FILE> ) {
                    last if( $line =~ /^\s*<\s*\/VirtualHost/ );
                    if( $line =~ /^\s*(\w+)\s+(.*)$/ ) {
                        $option->{KEY} = $1;
                        $option->{VALUE} = $2;
                        $tmpServerName = $2 if( $1 eq 'ServerName' ); # needed for hostid later
                        push( @$data, $option );
                        $option = {};
                    } else {
                        $option->{OVERHEAD} = $line;
                    }
                }
                $entry->{DATA} = $data;
                $entry->{HOSTID} = $entry->{VHOST}.'/'.$tmpServerName;
                $entry = {};
            } else {
                $entry->{OVERHEAD} .= $line;
            }
        }
        push( @{$vhost_files{$file}}, $entry );
        close( FILE );
    }

    return 1;
}

sub write_files {
    my $class = shift;

    if( open( FILE, "< /etc/apache2/listen.conf" ) ) {
        my @file = <FILE>;
        close(FILE);

        # drop all "NameVirtualHost" entries.
        foreach my $line ( @file ) {
            next unless( $line =~ /^NameVirtualHost/ );
            $line = "";
        }
        close(FILE);

        # do the new "NameVirtualHost" entries and save file
        foreach my $entry ( keys(%vhost_by_name) ) {
            push( @file, "NameVirtualHost $entry\n" );
        }
        open( FILE, "> /etc/apache2/listen.conf" ); #catch ERRORs
        print FILE @file;
        close(FILE);
    }

    foreach my $file ( keys(%vhost_files) ) {
        open( FILE, "> /etc/apache2/vhosts.d/$file" ) or do {
            y2error("open for /etc/apache2/vhosts.d/$file failed with $!");
            return 0;
        };
        foreach my $entry ( @{$vhost_files{$file}} ) {
            print FILE $entry->{OVERHEAD};
            print "<VirtualHost $entry->{VHOST}>\n" if( $entry->{VHOST} );
            foreach my $data ( @{$entry->{DATA}} ) {
                next if( $data->{KEY} eq 'HostIP' ); # just for internal use
                print FILE $data->{OVERHEAD} if( $data->{OVERHEAD} );
                print FILE " ".$data->{KEY}." ".$data->{VALUE}."\n" if( $data->{KEY} );
            }
            print FILE "</VirtualHost>\n" if( $entry->{VHOST} );
        }
        close(FILE);
    }
    return 1;
}

sub Execute {
    my $class = shift;
    my ($path, @args) = @_;

    return 1;
}


sub Read {
    my $class = shift;
    my ($path, @args) = @_;

     if( $path eq '.' ) {
        return \%vhost_files;
     } else {
        # not implemented
        retutrn {}
     }
}

sub Write {
    my $class = shift;
    my ($path, @args) = @_;

    if( $path eq '.' ) {
        write_files();
    } elsif( $path =~ /\.setFile\.(.*)/ ) {
        # args[0] = array ref (structure explained above)
        if( $1 ) {
            my $filename = $1;
            if( ref($args[0]) eq 'ARRAY' ) {
                $vhost_files{$filename} = $args[0];
            }
        } else {
            if( ref($args[0]) eq 'HASH' ) {
                %vhost_files = %{$args[0]};
            }
        }
    } else {
        # not implemented
    }
}

sub Dir {
}

package main;

ag_httpd_vhosts->Run ();

