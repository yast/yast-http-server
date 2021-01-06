#! /bin/sh

set -e
make -f Makefile.cvs
make install
./ci_package_check.rb
