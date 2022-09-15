# ***************************************************************************
#
# Copyright (c) 2002 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
require "yast"
require "y2packager/resolvable"

module Yast
  class HttpServerPackagesClass < Module
    include Yast::Logger

    def main
      textdomain "base"
    end

    # Tries to find a package according to the pattern
    #
    # @param pattern [String] a regex pattern to match, no escaping done
    # @return list of matching package names
    def by_pattern(pattern)
      raise ArgumentError, "Missing search pattern" if pattern.nil? || pattern.empty?

      init_packager

      # NOTE: - Resolvable.find takes POSIX regexp, later select uses Ruby regexp
      # - Resolvable.find supports regexps only for dependencies, so we need to
      # filter result according to package name
      Y2Packager::Resolvable.find({ provides_regexp: "^#{pattern}$" }, [:name])
        .select { |p| p.name =~ /\A#{pattern}\z/ }
        .map(&:name)
        .uniq
    end

    publish function: :by_pattern, type: "list <string> (string)"

  private
    # Makes sure the package database is initialized.
    def init_packager
      Pkg.TargetInitialize(Installation.destdir)
      Pkg.TargetLoad
      Pkg.SourceRestore
      Pkg.SourceLoad
    end
  end

  HttpServerPackages = HttpServerPackagesClass.new
  HttpServerPackages.main
end
