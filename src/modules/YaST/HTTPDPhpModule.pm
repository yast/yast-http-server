package YaST::HTTPDPhpModule;

our %TYPEINFO;

# Define globally the current PHP version
BEGIN { $TYPEINFO{Version} = ["function", "string" ]; }
sub Version {
    return "7";
}

1;
