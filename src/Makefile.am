#
# Makefile.am for devtools/devtools/skeletons/config/src
#

yncludedir = @yncludedir@/http-server

client_DATA =			\
	http-server.ycp		\
	http-server_auto.ycp	

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	routines.ycp

ydata_DATA =                     \
        all-apache2-modules.ycp

desktop_DATA =			\
	http-server.desktop

module_DATA =			\
	HTTPD.pm		\
	HTTPDModules.pm		\
	HttpServerWidgets.ycp	\
	HttpServer.ycp		

http-server:
	ln -sf . http-server

ycpchook = http-server

YCPCFLAGS=-I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(ydata_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
