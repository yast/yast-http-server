#! /bin/sh

set -e
make -f Makefile.cvs
make install
./travis_package_check.rb
