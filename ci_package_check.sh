#! /bin/sh

set -e
make -f Makefile.cvs
make install
# refresh the repositories from script, YaST wants to display
# a progress which does not work properly in GitHub Actions
zypper ref
./ci_package_check.rb
