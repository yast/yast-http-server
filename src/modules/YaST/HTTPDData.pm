package YaST::HTTPDData;
use YaST::YCP qw(:LOGGING sformat);
use YaPI::HTTPDModules;
use YaPI::HTTPD;
use YaST::httpdUtils;
use Data::Dumper;

@YaST::HTTPDData::ISA = qw( YaST::httpdUtils );

our $VERSION="0.01";
our %TYPEINFO;

use strict;
use Errno qw(ENOENT);

my %hosts;
my %certs;
my %dirty = ( NEW => {}, DEL => {}, MODIFIED => {} );


sub SetError {
    my $self = shift;
    return YaPI::HTTPD->SetError( @_ );
}

BEGIN { $TYPEINFO{Error} = ["function", [ "map", "string", "string" ] ]; }
sub Error {
    return YaPI::HTTPD->Error();
}

BEGIN { $TYPEINFO{ParseDirOption} = ["function", [ "map", "string", "any" ], "string" ]; }
sub ParseDirOption {
    my $self = shift;
    my $optionText = shift;
    my %ret = (
                'SECTIONNAME' => 'Directory',
                'KEY'         => '_SECTION',
                'VALUE'       => []
    );

    my @options = split( /\n/, $optionText );
    chomp(@options);
    $ret{SECTIONPARAM} = shift(@options);
    foreach my $option ( @options ) {
        my( $k,$v ) = split( /\s+/, $option, 2 );
        push( @{$ret{VALUE}}, { KEY => $k, VALUE => $v } );
    }
    return \%ret;
}

sub delDir {
    my $self = shift;
    my $dir = shift;
    my @newData = ();

    $dir =~ s/\/+/\//g;

    foreach my $e ( @{$hosts{'main'}} ) {
        next if( $e->{KEY} eq '_SECTION' and
                 $e->{SECTIONNAME} eq 'Directory' and
                 $e->{SECTIONPARAM} =~ /^"*$dir\/*"*/ );
        push( @newData, $e );
    }
    $hosts{'main'} = \@newData;
    $dirty{MODIFIED}->{'main'} = 1;
    return;
}

sub addDir {
    my $self = shift;
    my $dir = shift;
    $dir =~ s/\/+/\//g;
    $self->delDir( $dir ); # avoid double entries
    if( $dir =~ s/^"// ) { $dir =~s /"$// };

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
                     'KEY'   => 'Require',
                     'VALUE' => 'all granted'
                    }
                  ]
    };
    return $dirEntry;
}


#######################################################
# default and vhost API start
#######################################################

#bool ReadHosts();
BEGIN { $TYPEINFO{ReadHosts} = ["function", "boolean" ]; }
sub ReadHosts {
    my $self = shift;

    foreach my $hostid ( @{YaPI::HTTPD->GetHostsList()} ) {
    	$hosts{$hostid} = YaPI::HTTPD->GetHost($hostid) if( $hostid );
        if( not $self->FetchHostKey($hostid, 'SSLCACertificateFile') ) {
            $certs{$hostid}->{CA} = YaPI::HTTPD->ReadServerCA($hostid);
        }
        if( not $self->FetchHostKey($hostid, 'SSLCertificateFile') ) {
            $certs{$hostid}->{CERT} = YaPI::HTTPD->ReadServerCert($hostid);
        } 
        if( not $self->FetchHostKey($hostid, 'SSLCertificateKeyFile') ) {
            $certs{$hostid}->{KEY} = YaPI::HTTPD->ReadServerKey($hostid);
        }
    }
    return 1;
}

my @oldListen = ();
my %newListen = ();
my %delListen = ();

#bool ReadListen();
BEGIN { $TYPEINFO{ReadListen} = ["function", "boolean" ]; }
sub ReadListen {
    my $self = shift;
    @oldListen = @{YaPI::HTTPD->GetCurrentListen()};
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
    my $self = shift;
    @oldModuleSelections = @{YaPI::HTTPD->GetModuleSelectionsList()};
    @oldModules = @{YaPI::HTTPD->GetModuleList()};
    foreach my $mod ( YaPI::HTTPD->selections2modules([@oldModuleSelections]) ) {
	push(@oldModules, $mod) unless( grep/^$mod$/, @oldModules );
    }
    return 1;
}

my $serviceState;   # 1 = enable, 0=disable
BEGIN { $TYPEINFO{ReadService} = ["function", "boolean" ]; }
sub ReadService {
    my $self = shift;
    $serviceState = YaPI::HTTPD->ReadService();
}


#list<string> GetHostList();
BEGIN { $TYPEINFO{GetHostsList} = ["function", [ "list", "string"] ]; }
sub GetHostsList {
    my $self = shift;
    return YaPI::HTTPD->GetHostsList(); #[keys(%hosts)];
}

#map GetHost( string hostid );
BEGIN { $TYPEINFO{GetHost} = ["function", ["list", [ "map", "string", "any" ] ], "string"]; }
sub GetHost {
    my $self = shift;
    my $hostid = shift;

    return YaPI::HTTPD->GetHost($hostid); #exists($hosts{$hostid})?($hosts{$hostid}):[];
}


BEGIN { $TYPEINFO{GetVhostType} = ["function", [ "map", "string", "any" ], "string"]; }
sub GetVhostType {
    my $self = shift;
    my $hostid = shift;

 return YaPI::HTTPD->getVhType($hostid);
}


BEGIN { $TYPEINFO{GetHost} = ["function", ["list", [ "map", "string", "any" ] ], "string"]; }
sub getVhostType {
    my $self = shift;

}

#boolean ModifyHost( string hostid, list hostdata );
BEGIN { $TYPEINFO{ModifyHost} = ["function", "boolean", "string", ["list", [ "map", "string", "any" ] ] ]; }
sub ModifyHost {
    my $self = shift;
    my $hostid = shift;
    my $hostdata = shift;

    return undef if( ! $self->checkHostmap( $hostdata ) );
if ($hostid ne 'main')
 {

    YaPI::HTTPD->modifyVH($hostid, $hostdata);
    $dirty{MODIFIED}->{$hostid} = 1 unless( exists($dirty{NEW}->{$hostid}) );
 } else {
	 YaPI::HTTPD->modifyMain($hostdata);
	}
    return 1;
}

#bool CreateHost( string hostid, list hostdata );
BEGIN { $TYPEINFO{CreateHost} = ["function", "boolean", "string", [ "list", [ "map", "string", "any" ] ] ]; }
sub CreateHost {
    my $self = shift;
    my $hostid = shift;
    my $hostdata = shift;
    my $dir="";
    if( ! $self->checkHostmap( $hostdata ) ) {
        return undef;
    }
 # don't create Directory for DocumentRoot, if already exists
 if ($dir ne ""){
  foreach my $row (@$hostdata) {
   if ($row->{KEY} eq '_SECTION'){
 	$dir="" if ($row->{'SECTIONPARAM'} eq $dir->{'SECTIONPARAM'});
    }
   }
  }


push(@$hostdata, $dir) if ($dir);
#    $hosts{$hostid} = $hostdata;
    YaPI::HTTPD->createVH($hostid, $hostdata);
    $dirty{NEW}->{$hostid} = 1;
    delete($dirty{DEL}->{$hostid});
    delete($dirty{MODIFIED}->{$hostid});
    return 1;

}

sub getNVH {
    my $self = shift;
    my $value = shift;
    my $count = 0;

    foreach my $hostid ( keys(%hosts) ) {
        $hostid =~ /^([^\/]+)/;
        next unless( $value eq $1 );
        $count++;
    }
    return $count;
}

#bool DeleteHost( string hostid );
BEGIN { $TYPEINFO{DeleteHost} = ["function", "boolean", "string"]; }
sub DeleteHost {
    my $self = shift;
    my $hostid = shift;
    foreach my $h ( @{$hosts{$hostid}} ) {
	if( $h->{KEY} eq 'VirtualByName' and $h->{VALUE} ) {
            $hostid =~ /^([^\/]+)/;
            my $vhost = $1;
            # Am I the last one who uses this NameVirtualHost entry?
            if( $self->getNVH( $vhost ) == 1 ) {
                my @newData = ();
                while( my $e = shift(@{$hosts{'default'}}) ) {
                    if( $e->{KEY} eq 'NameVirtualHost' and
                        $e->{VALUE} eq $vhost ) {
                        push( @newData, @{$hosts{'default'}} );
                        last;
                    }
                    push( @newData, $e );
                }
                $hosts{'main'} = \@newData;
            }
        }
    }
    delete( $hosts{$hostid} );
    YaPI::HTTPD->deleteVH($hostid);
    $dirty{DEL}->{$hostid} = 1 unless( exists( $dirty{NEW}->{$hostid} ) );
    delete($dirty{NEW}->{$hostid});
    delete($dirty{MODIFIED}->{$hostid});
    return 1;
}

BEGIN { $TYPEINFO{WriteHosts} = ["function", "boolean" ]; }
sub WriteHosts {
    my $self = shift;

    YaPI::HTTPD->writeHosts();

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
    my $self = shift;
    my @ret;
    foreach my $mod ( @oldModules, keys(%newModules) ) {
        push( @ret, $mod ) unless( exists( $delModules{$mod} ) );
    }
    return \@ret;
}

# list<map> GetKnownModules()
BEGIN { $TYPEINFO{GetKnownModules} = ["function", [ "list", ["map","string","any"] ] ]; }
sub GetKnownModules {
    my $self = shift;
    # no state anyway, so we call the stateless API directly
    return \@{YaPI::HTTPD->GetKnownModules()}; 
}

# bool ModifyModuleList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleList} = ["function", "boolean", [ "list","string" ], "boolean" ]; }
sub ModifyModuleList {
    my $self = shift;
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
    my $self = shift;
    YaPI::HTTPD->ModifyModuleList( [ keys(%delModules) ], 0 ) if(keys(%delModules));
    YaPI::HTTPD->ModifyModuleList( [ keys(%newModules) ], 1 ) if(keys(%newModules));
    %delModules = ();
    %newModules = ();
    @oldModules = @{YaPI::HTTPD->GetModuleList()};

    my $use_ssl = 0;
    foreach( @{GetModuleList()} ){  $use_ssl = 1 if /^ssl$/ }

    my @flags = split(' ', YaPI::HTTPD->GetServerFlags());
    my $flags_have_ssl = 0;
    @flags = grep {
        if ($_ eq "SSL") {
            if ($use_ssl) {
                $flags_have_ssl = 1;
            } else {
                0;
            }
        } else {
            1;
        }
    } @flags;

    if ($use_ssl == 1 && $flags_have_ssl == 0) {
        push @flags, "SSL"
    }

    YaPI::HTTPD->SetServerFlags(join(" ", @flags));

    return 1;
}

# map GetKnownModulSelections()
BEGIN { $TYPEINFO{GetKnownModulSelections} = ["function", [ "map","string","any" ] ]; }
sub GetKnownModulSelections {
    my $self = shift;
    return @{YaPI::HTTPD->GetKnownModulSelections()};
}

# list<string> GetModuleSelectionsList()
BEGIN { $TYPEINFO{GetModuleSelectionsList} = ["function", ["list","string"] ]; }
sub GetModuleSelectionsList {
    my $self = shift;
    my @ret;
    foreach my $mod ( sort( @oldModuleSelections, keys(%newModuleSelections) ) ) {
        push( @ret, $mod ) unless( exists( $delModuleSelections{$mod} ) );
    }
    return \@ret;
}

# bool ModifyModuleSelectionList( list<string>, bool )
BEGIN { $TYPEINFO{ModifyModuleSelectionList} = ["function", "boolean", ["list","string"], "boolean" ]; }
sub ModifyModuleSelectionList {
    my $self = shift;
    my $newModules = shift;
    my $enable = shift;

    my @mods2sel = YaPI::HTTPD->selections2modules($newModules);
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
    my $self = shift;
    YaPI::HTTPD->ModifyModuleSelectionList( [ keys(%delModuleSelections) ], 0 );
    YaPI::HTTPD->ModifyModuleSelectionList( [ keys(%newModuleSelections) ], 1 );
    %newModuleSelections = ();
    %delModuleSelections = ();
    @oldModuleSelections = @{YaPI::HTTPD->GetModuleSelectionsList()};
    return 1;
}

#######################################################
# apache2 modules API end
#######################################################



#######################################################
# apache2 modify service
#######################################################

BEGIN { $TYPEINFO{GetService} = ["function", "boolean" ]; }
sub GetService {
    my $self = shift;
    return $serviceState;
}

# boolean ModifyService( boolean )
BEGIN { $TYPEINFO{ModifyService} = ["function", "boolean", "boolean" ]; }
sub ModifyService {
    my $self = shift;
    $serviceState = shift;
    return 1;
}

BEGIN { $TYPEINFO{WriteService} = ["function", "boolean", "boolean" ]; }
sub WriteService {
    my $self = shift;
    return YaPI::HTTPD->ModifyService( $serviceState );
}

#######################################################
# apache2 modify service end
#######################################################



#######################################################
# apache2 listen ports
#######################################################

# boolean CreateListen( int, int, list<string>, boolean )
# boolean CreateListen( int, int, list<string> )
BEGIN { $TYPEINFO{CreateListen} = ["function", "boolean", "integer", "integer", "string" ] ; }
sub CreateListen {
    my $self = shift;
    my $fromPort = shift;
    my $toPort = shift;
    my $ip = shift || ''; #FIXME: this is a list

    my $port = ($fromPort eq $toPort)?($fromPort):($fromPort.'-'.$toPort);
    delete($delListen{"$ip:$fromPort:$toPort"});

    foreach my $old ( @oldListen ) {
        if($ip and (exists($old->{ADDRESS}) and $ip eq $old->{ADDRESS}) and
            ($port eq $old->{PORT}) ) {
            return 1; # already created listen
        } elsif( not($ip) and (not(exists($old->{ADDRESS})) or $old->{ADDRESS} eq '') and
                 $port eq $old->{PORT} ) {
            return 1; # already created listen
        }
    }

    $newListen{"$ip:$fromPort:$toPort"} = 1;

    return 1;
}

# boolean DeleteListen( int, int, list<string> )
BEGIN { $TYPEINFO{DeleteListen} = ["function", "boolean", "integer", "integer", "string" ] ; }
sub DeleteListen {
    my $self = shift;
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
    my $self = shift;
    my @new;
    foreach my $new ( keys(%newListen) ) {
     my ($ip, $fp, $tp, $port) = ('', '', '', '');
	$new =~ m/\[([\w\W]*)\]/; #) {
      $ip=$1;
      if ($new =~ m/\[$ip\]:([\d\:]*)/){
       ($fp, $tp) = split(/:/, $1);
      } else{
             ( $ip, $fp, $tp ) = split(/:/, $new);
            }
      $tp=$fp if ($tp eq '');
      $port = ($fp eq $tp)?($fp):($fp.'-'.$tp);
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
    return \@new;
}

BEGIN { $TYPEINFO{WriteListen} = ["function", "boolean", "boolean" ]; }
sub WriteListen {
    my $self = shift;
    my $doFirewall = shift;
    my $ret = 1;
 
    foreach my $toDel ( keys(%delListen) ) {
     my ($ip, $fp, $tp, $port) = ('', '', '', '');
#     if (
      $toDel =~ m/\[([\w\W]*)\]/; #){
      $ip=$1;
      if ($toDel =~ m/\[$ip\]:([\d\:]*)/){
       ($fp, $tp) = split(/:/, $1);
      } else{
             ( $ip, $fp, $tp ) = split(/:/, $toDel);
            }
      $tp=$fp if ($tp eq '');
#      }
      $ip="[$ip]" if ($ip=~m/:/);
        YaPI::HTTPD->DeleteListen( $fp, $tp, $ip, $doFirewall );
    }
    foreach my $new ( keys(%newListen) ) {
     my ($ip, $fp, $tp, $port) = ('', '', '', '');
#     if (
      $new =~ m/\[([\w\W]*)\]/; #){
      $ip=$1 if ($1);
      if ($new =~ m/\[$ip\]:([\d\:]*)/){
       ($fp, $tp) = split(/:/, $1);
      } else{
             ( $ip, $fp, $tp ) = split(/:/, $new);
            }
      $tp=$fp if ($tp eq '');
      $port = ($fp eq $tp)?($fp):($fp.'-'.$tp);
#     }
        unless( YaPI::HTTPD->CreateListen( $fp, $tp, $ip, $doFirewall ) ) {
            $ret = undef;
        }
    }
    %delListen = ();
    %newListen = ();
    @oldListen = @{YaPI::HTTPD->GetCurrentListen()};
    return $ret;
}

#######################################################
# apache2 listen ports end
#######################################################



#######################################################
# apache2 packages
#######################################################

# list<string> GetPackagesForModule(string)
BEGIN { $TYPEINFO{GetPackagesForModule} = ["function", ["list", "string"], "string" ]; }
sub GetPackagesForModule {
    my $self = shift;
    my $mod = shift;
    my %uniq;

    if ( exists($YaPI::HTTPDModules::modules{$mod}) ) {
	@uniq{@{$YaPI::HTTPDModules::modules{$mod}->{packages}}} = ();
}
    return [ keys(%uniq) ];
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
# apache2 cert stuff 
#######################################################

sub GetCert {
    my $self = shift;
    my $hostid = shift;
    my $what = shift;
    my $ret = undef;

    if( $what =~ /^CERT|KEY|CA/ and exists($certs{$hostid}) ) {
        $ret = $certs{$hostid}->{$what};
    }
    return $ret;
}


BEGIN { $TYPEINFO{SetCert} = ["function", "boolean", "string", "string", "string" ]; }
sub SetCert {
    my $self   = shift;
    my $hostid = shift;
    my $what   = shift;
    my $data   = shift;
    my $ret = 0;

    if( $what =~ /^CERT|KEY|CA/ ) {
        if( $what eq 'CERT' and $data =~ /PRIVATE KEY/ ) {
            delete($certs{$hostid}->{KEY});
        }
        $certs{$hostid}->{$what} = $data;
        $dirty{MODIFIED}->{$hostid} = 1;
        $ret = 1;
    }
    return $ret;
}

BEGIN { $TYPEINFO{WriteCert} = ["function", "void", "string" ]; }
sub WriteCert {
    my $self = shift;
    my $hostid = shift;

     $self->ReadHosts();
    if( exists($certs{$hostid}) ) {
        if( exists( $certs{$hostid}->{'CERT'} ) ) {
            YaPI::HTTPD->WriteServerCert( $hostid, $certs{$hostid}->{'CERT'} );
        }
        if( exists( $certs{$hostid}->{'KEY'} ) ) {
            YaPI::HTTPD->WriteServerKey( $hostid, $certs{$hostid}->{'KEY'} );
        }
        if( exists( $certs{$hostid}->{'CA'} ) ) {
            YaPI::HTTPD->WriteServerCA( $hostid, $certs{$hostid}->{'CA'} );
        }
    }
}

#######################################################
# apache2 cert stuff end
#######################################################


# void InitializeDefaults ();
BEGIN { $TYPEINFO{InitializeDefaults} = ["function", "void" ]; }
sub InitializeDefaults {
    
    my $self = shift;

    my @knownModules = @{YaPI::HTTPD->GetKnownModules()}; 
    
    @oldModules = ();
    %newModules = ();
    %delModules = ();

    foreach my $mod ( @knownModules ) {
	my %module_hash = %{ $mod };
	
	if ( $module_hash{"default"} )
	{
	    push(@oldModules, $module_hash{"name"});
	}
    }
    
    @oldListen = ();
    %newListen = ();
    %delListen = ();

    $serviceState = 0;

    %hosts = ();
    %certs = ();
}

1;
