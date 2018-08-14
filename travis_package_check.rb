#! /usr/bin/env ruby

require "yast"

Yast.import "YaPI::HTTPD"
Yast.import "YaST::HTTPDData"
Yast.import "Pkg"

#
# Initialize the package manager
#
def init_pkg
    # Initialize the target
    Yast::Pkg.TargetInitialize("/")
    # Load the installed packages into the pool.
    Yast::Pkg.TargetLoad
    # Load the repository configuration. Refreshes the repositories if needed.
    Yast::Pkg.SourceRestore
    # Load the available packages in the repositories to the pool.
    Yast::Pkg.SourceLoad
end

#
# Collect all needed packages
#
# @return [Array<String>] package list
#
def apache_packages
    packages = Yast::YaST::HTTPDData.GetKnownModules.reduce([]) do |acc, m|
        acc.concat(m["packages"])
    end
    packages.uniq
end

puts "Checking the package availability..."
puts

init_pkg
packages = apache_packages

success = packages.reduce(true) do |acc, p|
    available = Yast::Pkg.PkgAvailable(p)
    puts "Package #{p} " + (available ? "OK" : "missing!")
    acc &&= available
end

exit(1) unless success
