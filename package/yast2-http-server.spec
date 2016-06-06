#
# spec file for package yast2-http-server
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-http-server
Version:        3.1.7
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
BuildRequires:	yast2-network docbook-xsl-stylesheets doxygen libxslt perl-XML-Writer popt-devel sgml-skel update-desktop-files yast2-packagemanager-devel yast2-perl-bindings yast2-testsuite libzio
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  yast2 >= 3.1.118
Requires:	yast2-network yast2-perl-bindings libzio
# DnsServerApi moved to yast2.rpm (bnc#392606)
# Wizard::SetDesktopTitleAndIcon
Requires:       yast2 >= 3.1.118

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - HTTP Server Configuration

%description
This package contains the YaST2 component for HTTP server (Apache2)
configuration.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/http-server
%{yast_schemadir}/autoyast/rnc/http-server.rnc
%{yast_yncludedir}/http-server/*
%{yast_clientdir}/http-server.rb
%{yast_clientdir}/http-server_*.rb
%{yast_moduledir}/*
%{yast_desktopdir}/http-server.desktop
%{yast_scrconfdir}/*
%{yast_agentdir}/*
%doc %{yast_docdir}
