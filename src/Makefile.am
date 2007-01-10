#
# Makefile.am for devtools/devtools/skeletons/config/src
#

yncludedir = @yncludedir@/http-server
rncdir =  $(schemadir)/autoyast/rnc
rnc_DATA = http-server.rnc

client_DATA =			\
	http-server.ycp		\
	http-server_auto.ycp	

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	wizard-dialog.ycp	\
	dialogs.ycp		\
	complex.ycp		\
	routines.ycp

desktop_DATA =			\
	http-server.desktop

module_DATA =			\
	HttpServerWidgets.ycp	\
	HttpServer.ycp		

http-server:
	ln -sf . http-server

YaPI_perldir = @moduledir@/YaPI

YaPI_perl_DATA = \
	YaPI/HTTPD.pm		\
	YaPI/HTTPDModules.pm

YaST_perldir = @moduledir@/YaST

YaST_perl_DATA = \
	YaST/HTTPDData.pm \
	YaST/httpdUtils.pm

ycpchook = http-server

YCPCFLAGS=-I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(ydata_DATA) $(desktop_DATA) $(YaPI_perl_DATA) $(YaST_perl_DATA)

include $(top_srcdir)/Makefile.am.common
