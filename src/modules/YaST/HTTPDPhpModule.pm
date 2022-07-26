package YaST::HTTPDPhpModule;

use YaST::YCP;

YaST::YCP::Import "Package";

our %TYPEINFO;

# Define globally the current PHP version
BEGIN { $TYPEINFO{Version} = ["function", "string" ]; }
sub Version {
    # when function returns an array, we get reference to it
    $l = Package->by_pattern("php[0-9]");

    return "" if(!$l);

    # there can be multiple versions of php
    @{$l} = sort @{$l};

    # package name is php<version> and we're interested in <version> only
    # we also take highest available version
    $l->[-1] =~ s/php([0-9]{1,2})$/$1/;

    return $l->[-1];
}

1;
