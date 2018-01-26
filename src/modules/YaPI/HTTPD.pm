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
  at boot time

SwitchService($state)

  $state is a boolean for turning on/off the apache2 service

ReloadService()

  function for reloading the apache2 service

$serviceState = ReadService()

  returns the state of the apache2 runlevel script as a boolean

CreateListen($fromPort,$toPort,$address,$doFirewall)

  $fromPort and $toPort are the listen ports. They can be the same.
  $address is the bind address and can be an empty string for 'all'
  $doFirewall is a boolean to write the listen data to firewalld

DeleteListen($fromPort,$toPort,$address,$doFirewall)

  $fromPort and $toPort are the listen ports. They can be the same.
  $address is the bind address and can be an empty string for 'all'
  $doFirewall is a boolean to delete the listen data from firewalld

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
 SECTIONNAME  => in case of a subsection, this is the sections name
 SECTIONPARAM => in case of a subsection, this is the section parameter

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

If you want to create subsections, the hash must look like this:

 { 
     KEY => '_SECTION',
     SECTIONNAME => 'Directory',
     SECTIONPARAM => '/srv/www/vhost13',
     OVERHEAD => "# vhost13 document root\n";
     VALUE => [
                {
                  KEY => 'Order',
                  VALUE => 'allow,deny'
                },
                {
                  ...
                }
              ]
 }

That will create a Directory subsection like this:

 # vhost13 document root
 <Directory /srv/www/vhost13>
   Order allow,deny
   ...
 </Directory>

Section can be nested as deep as you want. So a subsection
can contain further subsections.

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
will not end in a VirtualHost section but in the global definitions
in /etc/apache2/default-server.conf. Because of this, the default host
is more than just a simple host. It can also contain server directives
that aims for all vhosts too and for which no API function exists at
the moment (like alias creation for example).
You can not create or delete the default host id.

B<Example Code using the API>

 #!/usr/bin/perl -w

 use strict;
 # add YaST2 module path to the perl module path

 # load the HTTPD API
 use YaPI::HTTPD;

 # create the Host Data array 
 # see above for the data structure explanation
 my @temp = (
             { KEY => "ServerName",    VALUE => 'createTest2.suse.de' },
             { KEY => "VirtualByName", VALUE => 0 },
             { KEY => "ServerAdmin",   VALUE => 'no@one.de' },
             { KEY => "HostIP",        VALUE => '*:80' }
            );

 # create the host now. This will directly affect the config files of
 # the apache2. So, after this call, there will be a new vhost in
 # /etc/apache2/vhosts.d/yast2_vhosts.conf
 my $ret = YaPI::HTTPD->CreateHost( '*:80/createTest2.suse.de', \@temp );

 # the CreateHost call will return "undef" in case of an error. We should
 # check this here and print all error information we can get
 unless( $ret ) {
     my %error = %{YaPI::HTTPD->Error()};
     foreach(keys %error) {
         print "$_ = $error{$_}\n";
     }
 }


=head1 DESCRIPTION

=over 2

=cut

package YaPI::HTTPD;
use Data::Dumper;
use YaPI;
use YaST::YCP qw(:LOGGING sformat);
use YaPI::HTTPDModules;
use YaST::httpdUtils;
use YaST::HTTPDData;
use Data::Dumper;
@YaPI::HTTPD::ISA = qw( YaPI YaST::httpdUtils YaST::HTTPDData );
YaST::YCP::Import ("SCR");
YaST::YCP::Import ("Service");
YaST::YCP::Import ("FirewalldWrapper");
textdomain "http-server";

#######################################################
# temoprary solution end
#######################################################
our $VERSION='1.0.0';
our @CAPABILITIES = ('SLES9');
our %TYPEINFO;

use strict;
use Errno qw(ENOENT);
#######################################################
# default and vhost API start
#######################################################
my $vhost_files = undef;

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
    if (!defined $vhost_files) {
	my @data = $self->readHosts();
	$vhost_files = $data[0];
    }

    foreach my $key (sort keys (%{$vhost_files})) {
        if($key eq "ip-based") {
            foreach my $hostList ($vhost_files->{'ip-based'}) {
                foreach my $hostentryHash (@$hostList) {
                    push (@ret, $hostentryHash->{HOSTID}) if ($hostentryHash->{HOSTID});
                }
            }
        }
        elsif($key eq "main") {
            push (@ret, $vhost_files->{'main'}{HOSTID}) if (defined ($vhost_files->{'main'}{HOSTID}));
        }
        else {
            foreach my $hostList ( $vhost_files->{$key} ) {
                foreach my $hostentryHash ( @$hostList ) {
                    push (@ret, $hostentryHash->{HOSTID}) if ($hostentryHash->{HOSTID});
                }
            }
        }
    }

    return \@ret;
}

=item *
C<$hostData = GetHost($hostid);>

This function returns a reference to a host data list.
The format of the Host data list is described above.
In case of an error (for example, if there is no host
with such an id) undef is returned.

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

    if (!defined $vhost_files) {
	my @data = $self->readHosts();
	$vhost_files = $data[0];
    }

    my $ret=undef;

    foreach my $key (sort keys (%{$vhost_files})) {
        if($key eq "ip-based") {
            foreach my $hostList ( $vhost_files->{'ip-based'} ) {
                foreach my $hostentryHash (@$hostList) {
                    $ret = $hostentryHash if (($hostentryHash->{HOSTID}) && ($hostentryHash->{HOSTID} eq $hostid));
                }
            }
        }
        elsif($key eq "main") {
            $ret = $vhost_files->{'main'}
            if ((defined $vhost_files->{'main'}{HOSTID}) && ($vhost_files->{'main'}{HOSTID} eq $hostid));
        }
        else {
            foreach my $hostList ($vhost_files->{$key}) {
                foreach my $hostentryHash (@$hostList) {
                    $ret = $hostentryHash if (($hostentryHash->{HOSTID}) && ($hostentryHash->{HOSTID} eq $hostid));
                }
            }
        }
    }

    return [@{$ret->{'DATA'}}] if (defined $ret);
    return [];
}

BEGIN { $TYPEINFO{getVhType} = ["function", [ "map", "string", "any" ], "string"]; }
sub getVhType {
    my $self = shift;
    my $hostid = shift;

    my %ret = ();

    foreach my $key (keys (%{$vhost_files})) {
        if($key eq "ip-based") {
            foreach my $hostList ($vhost_files->{'ip-based'}) {
                foreach my $hostentryHash (@$hostList) {
                    %ret = (type => 'ip-based', id => $hostentryHash->{HostIP})
                        if (($hostentryHash->{HOSTID}) && ($hostentryHash->{HOSTID} eq $hostid));
                }
            }
        }
        elsif($key eq "main") {
            %ret = (type => 'main')
                if ((defined $vhost_files->{'main'}{HOSTID}) && ($vhost_files->{'main'}{HOSTID} eq $hostid));
        }
        else {
            foreach my $hostList ($vhost_files->{$key}) {
                foreach my $hostentryHash (@$hostList) {
                    %ret = (type => 'name-based',id => $hostentryHash->{HostIP})
                        if (($hostentryHash->{HOSTID}) && ($hostentryHash->{HOSTID} eq $hostid));
                }
            }
        }
    }

    return \%ret;
}

sub createVH (){
    my $self = shift;
    my $hostid = shift;
    my $data = shift;
    my $params = shift;

    my $byname = "";
    my $ip = "";
    my $servername = "";

 my @newdata = ();
 foreach my $row (@{$data}){
  if ($row->{KEY} eq 'HostIP' ) {
    $ip = $row->{VALUE};
   } elsif ($row->{KEY} eq 'VirtualByName' ) {
	 $byname = $row->{VALUE};		
	}else {
		$servername = $row->{VALUE} if ($row->{KEY} eq 'ServerName');
	 	push(@newdata, $row);
	}
 }

 if ($ip eq '' && $byname eq ''){
  $ip = $params->{'id'} if defined($params->{'type'});
  if (defined($params->{'type'}) && $params->{'type'} eq "ip-based"){
   $byname = "0";
  } else {
	 $byname = "1";
 	}
 }


 if ($byname eq 0){
	 push(@{$vhost_files->{'ip-based'}},  {HOSTID => "$ip/$servername", HostIP => $ip, DATA => \@newdata});
	} else {
		 $vhost_files->{$servername} =  [{HOSTID => "$ip/$servername", HostIP => $ip, DATA => \@newdata}];
		}

 $self->validateNVH();
}


sub deleteVH () {
    my $self = shift;
    my $hostid = shift;

    foreach my $key (keys (%{$vhost_files})) {
        if($key eq "ip-based") {
            foreach my $hostList ($vhost_files->{'ip-based'}) {
                my @tmp_list = ();
                foreach my $hostentryHash (@$hostList) {
			push(@tmp_list, $hostentryHash) if ($hostid ne $hostentryHash->{HOSTID});
                }
                $vhost_files->{'ip-based'} = \@tmp_list;
            }
        }
        elsif($key eq "main") {
            delete $vhost_files->{'main'} if ($hostid eq 'main');
        }
        else {
            my $vhost = $vhost_files->{$key}->[0]->{'HOSTID'};
            delete $vhost_files->{$key} if ($vhost eq $hostid);
        }
    }
}


sub modifyMain {
    my $self = shift;
    my $data = shift;

    $vhost_files->{'main'}{'DATA'} = $data;
}

sub modifyVH {
    my $self = shift;
    my $hostid = shift;
    my $data = shift;


    my $params = $self->getVhType($hostid);

    $self->deleteVH($hostid);
    $self->createVH($hostid, $data, $params);
}

sub validateNVH (){
    my %nb = ();
    foreach my $key ( keys( %{$vhost_files} ) ){
       if(($key ne 'ip-based') && ($key ne 'main')){
	my $host_ip=$vhost_files->{$key}->[0]->{'HostIP'};
	$nb{$host_ip}=1 if ($host_ip);
       }
    }

  my @tmp_data=();
  foreach my $row (@{$vhost_files->{main}{DATA}}){
   push(@tmp_data, $row) if ($row->{KEY} ne 'NameVirtualHost');
  }
  $vhost_files->{main}{DATA} = \@tmp_data;


 foreach my $ip (keys %nb){
  push(@{$vhost_files->{main}{DATA}}, {KEY=>'NameVirtualHost', VALUE=>$ip} );
 }

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
        return $self->SetError( %{SCR->Error(".http_server.vhosts")} );
    }

    my $filename = $self->getFileByHostid( $hostid, $vhost_files );
    return undef if( not $self->checkHostmap( $newData ) );
    foreach my $entry ( @{$vhost_files->{$filename}} ) {
        if( $entry->{HOSTID} eq $hostid ) {
            my @tmp;
	    my $ssl_require=0;
            foreach my $tmp ( @$newData ) {
                if( $tmp->{'KEY'} eq 'VirtualByName' ) {
                    $entry->{VirtualByName} = $tmp->{'VALUE'};
                    next;
                } 
		elsif( $hostid ne 'default' and $tmp->{KEY} =~ /ServerTokens|TimeOut|ExtendedStatus/ ) {
                    # illegal keys in vhost
                    return $self->SetError( summary => sprintf( __("Illegal key in virtual host '%s'."),$tmp->{KEY}),
                                            code    => "CHECK_PARAM_FAILED" );
                } else {
                    push( @tmp, $tmp );
                }
            }

            $entry->{DATA} = \@tmp;
            $self->writeHost( $filename, $vhost_files );

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
                SCR->Write('.sysconfig.apache2',undef);
            }
            return 1;
        }
    }
    return 0; # host not found. Error?
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
        return $self->SetError( summary => sprintf(__("Internal Error: Data must be an array ref and not %s."),ref($data)), 
                                code => "CHECK_PARAM_FAILED" );
    }
    my $sslHash = { KEY => 'SSLEngine' , VALUE => 'off' };
    my @tmp = ( $sslHash );
    my $VirtualByName = 0;
    my $docRoot = "";
    foreach my $key ( @$data ) {
        # VirtualByName and SSL get dropped/replaced
        if( $key->{KEY} eq 'VirtualByName' ) {
            $VirtualByName = $key->{VALUE};
        } 
if( $key->{KEY} =~ /ServerTokens|TimeOut|ExtendedStatus/ ) {
            # illegal keys in vhost
            return $self->SetError( summary => sprintf(__("Illegal key in virtual host '%s'."), $key->{KEY}),
                                    code    => "CHECK_PARAM_FAILED" );
        } else {
            push( @tmp, $key );
        }
    }
    $data = \@tmp;
    return undef if( not $self->checkHostmap( $data ) );

    $hostid =~ /^([^\/]+)/;
    my $vhost = $1;
    return $self->SetError( summary => __("Illegal host ID."),
                            code    => "CHECK_PARAM_FAILED" ) unless( $vhost );
    my $entry = {
                 OVERHEAD      => "# YaST generated vhost entry\n",
                 VirtualByName => $VirtualByName,
                 HOSTID        => $hostid,
                 HostIP        => $vhost,
                 DATA          => $data
    };
    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = $self->readHosts();
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return $self->SetError( %{SCR->Error(".http_server.vhosts")} );
    }

    # already exists check
    foreach my $hostHash ( @{$vhost_files->{'yast2_vhosts.conf'}} ) {
        if( exists($hostHash->{HOSTID}) and $hostHash->{HOSTID} eq $hostid ) {
            return $self->SetError( summary => __('hostid already exists'), code => "CHECK_PARAM_FAILED" );
        }
    }

    if( $self->isVirtualByName($vhost, $vhost_files) and !$VirtualByName) {
        return $self->SetError( summary => 'ip based host on virtual by name interface', code => "CHECK_PARAM_FAILED");
    }
    if( ! $self->isVirtualByName($vhost, $vhost_files) and $VirtualByName) {
        return $self->SetError( summary => 'name based host on none name based interface', code => "CHECK_PARAM_FAILED");
    }

    if( ref($vhost_files->{'yast2_vhosts.conf'}) eq 'ARRAY' ) {
        # merge new entry with existing entries in yast2_vhosts.conf
        push( @{$vhost_files->{'yast2_vhosts.conf'}}, $entry );
    } else {
        # create new yast2_vhosts.conf
        $vhost_files->{'yast2_vhosts.conf'} = [ $entry ];
    }
    return $self->writeHost( 'yast2_vhosts.conf', $vhost_files );
}

=item *
C<DeleteHost($hostid)>

This function removes the host with $hostid.
If the hostid is not found, undef is returned.

EXAMPLE
 DeleteHost( '192.168.1.2/createTest2.suse.de' );

=cut

#bool DeleteHost( string hostid );
BEGIN { $TYPEINFO{DeleteHost} = ["function", "boolean", "string"]; }
sub DeleteHost {
    my $self = shift;
    my $hostid = shift;

    if( $hostid eq 'default' ) {
        return $self->SetError( summary => __('can not delete default host'), code => "CHECK_PARAM_FAILED" );
    }
    # FIXME
    # will read all vhost files, even if the vhost is found
    # in the first file.
    my @data = $self->readHosts();
    if( ref($data[0]) eq 'HASH' ) {
        $vhost_files = $data[0];
    } else {
        return $self->SetError( %{SCR->Error(".http_server.vhosts")} );
    }
    my $filename = $self->getFileByHostid( $hostid, $vhost_files );
    my @newList = ();
    my $found = 0;
    foreach my $hostHash ( @{$vhost_files->{$filename}} ) {
        if( exists($hostHash->{HOSTID}) and $hostHash->{HOSTID} ne $hostid ) {
            push( @newList, $hostHash );
        } else {
            $found = 1;
        }
    }
    return $self->SetError( summary => __('hostid not found'), code => "CHECK_PARAM_FAILED" ) unless( $found );
    if( @newList ) {
        $vhost_files->{$filename} = \@newList;
    } else {
        delete($vhost_files->{$filename}); # drop empty file
    }
    return $self->writeHost( $filename, $vhost_files );
}

sub writeHosts (){
    my $self = shift;

    # default server
    my %data = ( 'default-server.conf' =>$vhost_files->{'main'});

    #ip based vhost
    my @ip_vhosts = @{$vhost_files->{'ip-based'}} if (defined $vhost_files->{'ip-based'}); 
    my $size = @ip_vhosts;
    $data{'ip-based_vhosts.conf'} = \@ip_vhosts if ($size>0);

    #name based vhost
    foreach my $vhost ( keys(%{$vhost_files}) ) {
      next if ($vhost eq 'main' || $vhost eq 'ip-based');
      my @name_vhost = @{$vhost_files->{$vhost}};
      $data{"$vhost.conf"} = \@name_vhost;
    }

 SCR->Write(".http_server.vhosts", \%data);
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
This is more or less just the content of the sysconfig
variable "APACHE_MODULES" from /etc/sysconfig/apache2.

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
#    my $data = SCR->Read('.sysconfig.apache2.APACHE_MODULES'); # FIXME: Error handling
    my $data = SCR->Execute('.target.bash_output', 'a2enmod -l')->{'stdout'}; # FIXME: Error handling

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

optional keys are:
module    => a hash reference like: { SSLEngine => 'SSL' } which means, that
the SSLEngine keyword will be wrapped in a <IfModule SSL> block.

define    => like the module keyword, but it's a <IfDefine SSL> block

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
This modifes more or less just the content of the sysconfig
variable "APACHE_MODULES" from /etc/sysconfig/apache2.
Unknown modules are allowed too but they will be appendet to
the end of the list.

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

   # change order for modules:
   # known first, then unknown
   my @known=();
   my @unknown=();
   foreach my $module (@newList){
    if (grep (/^$module$/, (keys %YaPI::HTTPDModules::modules))){
     push(@known, $module);
    } else {
         push(@unknown, $module);
        }
    }
    @newList = (@known, @unknown);

    SCR->Execute('.target.bash', 'for module in $(a2enmod -l);do a2enmod -d $module; done');
    foreach my $module (@newList){
    	SCR->Execute('.target.bash', "a2enmod $module");
    }
#    SCR->Write('.sysconfig.apache2.APACHE_MODULES', join(' ',@newList));
#    SCR->Write('.sysconfig.apache2', undef);
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

this function returns a reference to an array that
contains strings with the names of the active module
selections.

EXAMPLE

 my $selList = GetModuleSelectionsList();
 print "active selections: ".join(',', @$selList)."\n";

=cut

#BEGIN { $TYPEINFO{GetModuleSelectionsList} = ["function", ["list","string"] ]; }
#sub GetModuleSelectionsList {
#    my $self = shift;
#    return (SCR->Read('.http_server.moduleselection'))[0];
#}

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

#BEGIN { $TYPEINFO{ModifyModuleSelectionList} = ["function", "boolean", ["list","string"], "boolean" ]; }
#sub ModifyModuleSelectionList {
#    my $self = shift;
#    my $newSelection = shift;
#    my $enable = shift;
#    my %uniq = ();

#    @uniq{@{$self->GetModuleSelectionsList()}} = ();
#    if( $enable ) {
#        @uniq{@$newSelection} = ();
#        foreach my $ns ( @$newSelection ) {
#            $self->ModifyModuleList( $HTTPModules::selection{$ns}->{modules}, 1 );
#            $self->ModifyModuleList( [], 1 );
#        }
#    } else {
#        delete(@uniq{@$newSelection});
#        foreach my $ns ( @$newSelection ) {
#            $self->ModifyModuleList( $HTTPModules::selection{$ns}->{modules}, 0 );
#            $self->ModifyModuleList( [], 1 );
#        }
#    }

#    SCR->Write('.http_server.moduleselection', [keys(%uniq)]);
#}

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

 ModifyService(0); # turn apache2 off at boot time
 ModifyService(1); # turn apache2 on at boot time

=cut

BEGIN { $TYPEINFO{ModifyService} = ["function", "boolean", "boolean" ]; }
sub ModifyService {
    my $self = shift;
    my $enable = shift;

    if( $enable ) {
        Service->Adjust( "apache2", "enable" );
    } else {
        Service->Adjust( "apache2", "disable" );
    }
    return 1;
}

=item *
C<SwitchService($status)>

with this function you can start and stop the apache2
service.

EXAMPLE

 SwitchService( 0 ); # turning off the apache2 service
 SwitchService( 1 ); # turning on the apache2 service

=cut

sub SwitchService {
    my $self = shift;
    my $enable = shift;

    if( $enable ) {
        Service->RunInitScript( "apache2", "restart");
    } else {
        Service->RunInitScript( "apache2", "stop" );
    }
}

=item *
C<ReloadService($status)>

with this function you can reload the apache2 service

EXAMPLE

 ReloadService();

=cut

sub ReloadService {
    my $self = shift;
    return Service->RunInitScript( "apache2", "reload");
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
=item *
C<CreateListen( $fromPort, $toPort, $listen, $doFirewall )>

with this function you can configure the addresses and ports
the webserver is listening on. $fromPort and $toPort can have
the same value. $listen must be a network interface of the
host but can be an empty string for 'all' interfaces.
The $doFirewall boolean indicates if 'firewalld' shall be
configured for the settings.

EXAMPLE

 CreateListen( 80, 80, '127.0.0.1', 0 );   # localhost without firewall setup
 CreateListen( 443, 443, '', 1 );          # HTTPS on all interfaces
 CreateListen( 80, 80, '192.168.0.1', 1 ); # internal+firewall setup

=cut

BEGIN { $TYPEINFO{CreateListen} = ["function", "boolean", "integer", "integer", [ "list", "string" ], "boolean" ] ; }
sub CreateListen {
    my $self       = shift;
    my $fromPort   = shift;
    my $toPort     = shift;
    my $ip         = shift; #FIXME: this is a list
    my $doFirewall = shift;

    if( $fromPort < 0 or $fromPort > 65535 or
        $toPort   < 0 or $toPort   > 65535 or
        $fromPort > $toPort ) {
        return $self->SetError( summary => __('illegal port'), code => "CHECK_PARAM_FAILED" );
    }
    my @listenEntries = @{$self->GetCurrentListen()};
    my %newEntry;
    $newEntry{ADDRESS} = '';
    $newEntry{ADDRESS} = $ip if ($ip);
    $newEntry{ADDRESS} = "[$ip]" if ($ip=~m/\:/);
    $newEntry{PORT} = ($fromPort eq $toPort)?($fromPort):($fromPort.'-'.$toPort);
y2warning("SCR::WRITE listentries", Dumper(\@listenEntries), "new entry ", Dumper(\%newEntry));
    SCR->Write( ".http_server.listen", [ @listenEntries, \%newEntry ] );

    if( $doFirewall ) {
        my $ip2device = $self->ip2device();
        my $if = exists($newEntry{ADDRESS})?$ip2device->{$newEntry{ADDRESS}}:'all';
        FirewalldWrapper->read();
        unless( FirewalldWrapper->add_port( $newEntry{PORT}, "TCP", $if ) ) {
            return $self->SetError( code    => 'SET_FW_FAILED',
                                    summary => __('writing the firewall rules failed') );
        } else {
            FirewalldWrapper->write();
        }
    }
    return 1;
}

=item *
C<DeleteListen( $fromPort, $toPort, $listen, $doFirewall )>

with this function you can delete an address and port
the webserver is listening on. $fromPort and $toPort can have
the same value. $listen must be a network interface of the
host but can be an empty string for 'all' interfaces.
If the listen parameter can't be found, undef is returned.
The $doFirewall boolean indicates if firewalld shall be
configured for the settings.

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
        if( $ip and (not exists($listen->{'ADDRESS'}) or $listen->{'ADDRESS'} ne $ip) ) {
            push( @newListenEntries, $listen );
            next;
        }
        next if( "$fromPort-$toPort" eq $listen->{'PORT'} );
        next if( ($fromPort eq $toPort) and $listen->{'PORT'} eq $fromPort );
        push( @newListenEntries, $listen );
    }
    if( @listenEntries == @newListenEntries ) {
        return $self->SetError( summary => __('listen value to delete not found'), code => "CHECK_PARAM_FAILED" );
    }

    SCR->Write( ".http_server.listen", \@newListenEntries );
    if( $doFirewall ) {
        my $ip2device = $self->ip2device();
        my $if = $ip?$ip2device->{$ip}:'all';
        my $port = ($fromPort eq $toPort)?($fromPort):("$fromPort-$toPort");
        FirewalldWrapper->read();
        FirewallWrapper->remove_port( $port, "TCP", $if );
        FirewalldWrapper->write();
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
On error, undef is returned

EXAMPLE

 my $listenList = GetCurrentListen();
 foreach my $ld ( @$listenList ) {
     print "Listening on: ".$ld->{ADDRESS}."/".$ld->{PORT}."\n";
 }

=cut

# http://httpd.apache.org/docs/2.2/mod/mpm_common.html#listen
# We support 3 possible values for Listen :
# [IPv6]:port
# IPv4:port
# port
#

BEGIN { $TYPEINFO{GetCurrentListen} = ["function", ["list", [ "map", "string", "any" ] ] ]; }
sub GetCurrentListen {
    my $self = shift;
    my @data = SCR->Read('.http_server.listen');
    my @ret;
    if( not ref($data[0]) ) {
        return $self->SetError( %{SCR->Error(".http_server.listen")} );
    }
    foreach my $new ( @{$data[0]} ) {
     my ($ip, $port) = ('', '');
     if ($new =~ m/\[([\w\W]*)\]([\w\W]*)/){
      $ip="[$1]";
      $new=$2;
     } elsif ($new =~ m/([\d\.]*):([\w\W]*)/){
	$ip=$1;
	$new=$2;
     }

     if ($new =~/[\D]*([\d]*)[\D]*/){
      $port=$1;
     }
    push(@ret, {ADDRESS => $ip, PORT=>$port});
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
C<$packList = GetServicePackages()>

this function returns a list of strings with the needed RPM
packages for this service.

EXAMPLE

 my $packList = GetServicePackages();
 foreach my $pack ( @$packList ) {
     print "$pack needs to be installed to run this service\n";
 }


=cut

BEGIN { $TYPEINFO{GetServicePackages} = ["function", ["list", "string" ] ]; }
sub GetServicePackages {
    my $self = shift;
    return [ 'apache2' ];
}

=item *
C<$packList = GetModulePackages()>

this function returns a list of strings with the needed RPM
pacakges for all activated apache2 modules.

EXAMPLE

 my $packList = GetModulePackages();
 foreach my $pack ( @$packList ) {
     print "$pack needs to be installed to run the selected modules\n";
 }


=cut

BEGIN { $TYPEINFO{GetModulePackages} = ["function", ["list", "string"] ]; }
sub GetModulePackages {
    my $self = shift;
#    my $mods = $self->GetModuleList();
    my $mods = YaST::HTTPDData->GetModuleList();
    my %uniq;
    foreach my $mod ( @$mods ) {
    if ( exists($YaPI::HTTPDModules::modules{$mod}) ) {
        @uniq{@{$YaPI::HTTPDModules::modules{$mod}->{packages}}} = ();
	}
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
    SCR->Write('.sysconfig.apache2', undef);
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
If the $pemData is undefined, an old certificate gets
deleted and SSLCertificateFile directive gets dropped.
Writing the server certificate does not turn on SSL
automatically.
On failure, undef is returned.
The path for writing the certificate is
/etc/apache2/ssl.crt the filename is $hostname-cert.pem

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
    my $key = (defined($pemData) and $pemData =~ /PRIVATE KEY/)?(1):(0);

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => __("Unable to fetch a host with the specified ID."),
                                code    => "PARAM_CHECK_FAILED" );
    }
    my $file = '/etc/apache2/ssl.crt/';
    $file .= $self->FetchHostKey($host,'ServerName') || 'default';
    $file .= '-cert.pem';

    if( not $pemData ) {
    } elsif( $pemData !~ /BEGIN CERTIFICATE/ ) {
        return $self->SetError( summary => __("Corrupt PEM data."), code => 'CERT_ERROR' );
    } else {
        SCR->Write( '.target.string', $file, $pemData );
        SCR->Execute( '.target.bash', "chmod 0400 $file" );
    }
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
If the $pemData is undefined, an old key gets
deleted and SSLCertificateKeyFile directive gets dropped.
Writing the server key does not turn on SSL automatically.
On failure, undef is returned.
The path for writing the keyfile is
/etc/apache2/ssl.key the filename is $hostname-key.pem

EXAMPLE

  WriteServerCert('*:443', $certData);
  WriteServerKey('*:443', $keyData);

=cut


sub WriteServerKey {
    my $self = shift;
    my $hostid = shift;
    my $pemData = shift;
    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => __("Unable to fetch a host with the specified ID."), code => "PARAM_CHECK_FAILED" );
    }
    my $file = '/etc/apache2/ssl.key/';
    $file .= $self->FetchHostKey($host,'ServerName') || 'default';
    $file .= '-key.pem';

    if( not $pemData ) {
    } elsif( $pemData !~ /PRIVATE KEY/ ) {
        return $self->SetError( summary => __("Corrupt PEM data."), code => 'CERT_ERROR' );
    } else {
        my $cert = ($pemData =~ /BEGIN CERTIFICATE/)?(1):(0);
        SCR->Write( '.target.string', $file, $pemData );
        SCR->Execute( '.target.bash', "chmod 0400 $file" );
    }
    return $self->ModifyHost( $hostid, $host );
}

=item *
C<WriteServerCA($hostID, $pemData)>

this function writes the server CA for the
host with $hostID to the right place and sets the
SSLCACertificateFile directive to the right path.
The CA must be in PEM format.
If the $pemData is undefined, an old CA file gets
deleted and SSLCACertificateFile directive gets dropped.
Writing the server CA does not turn on SSL automatically.
On failure, undef is returned.
The path for writing the ca certificate file is
/etc/apache2/ssl.crt the filename is $hostname-cacert.pem

EXAMPLE

  WriteServerCA($hostID, $pemData);

=cut


sub WriteServerCA {
    my $self = shift;
    my $hostid = shift;
    my $pemData = shift;

    my $host = $self->GetHost( $hostid );
    unless( ref($host) ) {
        return $self->SetError( summary => __("Unable to fetch a host with the specified ID."), code => "PARAM_CHECK_FAILED" );
    }
    my $file = '/etc/apache2/ssl.crt/';
    $file .= $self->FetchHostKey($host, 'ServerName') || 'default';
    $file .= '-cacert.pem';

    if( not $pemData ) {
        SCR->Execute( '.target.remove', $file );
        $self->ModifyHostKey( $host, 'SSLCACertificateFile' );
    } elsif( $pemData !~ /BEGIN CERTIFICATE/ ) {
        return $self->SetError( summary => __("Corrupt PEM data."), code => 'CERT_ERROR' );
    } else {
        my $cert = SCR->Write( '.target.string', $file, $pemData );
        SCR->Execute( '.target.bash', "chmod 0400 $file" );
        $self->ModifyHostKey( $host, 'SSLCACertificateFile', $file );
    }

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
        return $self->SetError( summary => ("Unable to fetch a host with the specified ID."), code => "PARAM_CHECK_FAILED" );
    }
    my $file = '';
    $file .= $self->FetchHostKey( $host, 'SSLCertificateFile' ) || '';
    if( $file eq '' ) {
        return $self->SetError( summary => ("No certificate file configured for this host ID."), code => "CERT_ERROR" );
    }
    my $cert = SCR->Read( '.target.string', $file );
    unless( $cert ) {
        return $self->SetError( %{SCR->Error(".target.string")} );
    }
    $cert =~ /(-----BEGIN CERTIFICATE-----[^-]+-----END CERTIFICATE-----)/;
    if( ! $1 ) {
        return $self->SetError( summary => ("Parsing the certificate file failed."), code => "CERT_ERROR" );
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
        return $self->SetError( summary => __("Unable to fetch a host with the specified ID."), code => "PARAM_CHECK_FAILED" );
    }
    my $file = '';
    $file .= $self->FetchHostKey( $host, 'SSLCertificateKeyFile' ) || '';
    if( $file eq '' ) {
        $file .= $self->FetchHostKey( $host, 'SSLCertificateFile' ) || '';
        if( $file eq '' ) {
            return $self->SetError( summary => __("No certificate key file configured for this host ID."), code => 'CERT_ERROR' );
        }
    }
    my $cert = SCR->Read( '.target.string', $file );
    unless( $cert ) {
        return $self->SetError( %{SCR->Error(".target.string")} );
    }
    $cert =~ /(-----BEGIN RSA PRIVATE KEY-----.+)/s;
    if( ! $1 ) {
        return $self->SetError( summary => __("Parsing the key file failed."), code => 'CERT_ERROR' );
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
        return $self->SetError( summary => __("Unable to fetch a host with the specified ID."), code => "PARAM_CHECK_FAILED" );
    }
    my $file = '';
    $file .= $self->FetchHostKey( $host, 'SSLCACertificateFile' ) || '';
    if( $file eq '' ) {
        return $self->SetError( summary => __("No CA certificate file configured for this host ID."), code => 'CERT_ERROR' );
    }
    my $cert = SCR->Read( '.target.string', $file );
    unless( $cert ) {
        return $self->SetError( %{SCR->Error(".target.string")} );
    }
    return $cert;
}

#######################################################
# apache2 ssl certificates end
#######################################################
1;
