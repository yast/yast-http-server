package YaST::HTTPDPhpModule;

use YaST::YCP;

YaST::YCP::Import "Package";

our %TYPEINFO;

# Define globally the current PHP version
BEGIN { $TYPEINFO{Version} = ["function", "string" ]; }
sub Version {
    # when function returns an array, we get reference to it
    $l = Package->by_pattern("php[0-9]{1,2}");

    return if(!$l);

    # there can be multiple versions of php and
    # package name is php<version>. We're interested in <version> only
    # Take highest available version
    @s = map { int($_ =~ s/php([0-9]{1,2})$/$1/r) } @{$l};
    @s = sort {$a <=> $b} @s;

    return $s[-1];
}

1;
