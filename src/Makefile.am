# Sources for http-server

module_DATA = \
  modules/HttpServer.rb \
  modules/HttpServerWidgets.rb

module1dir = @moduledir@/YaPI
module1_DATA = \
  modules/YaPI/HTTPDModules.pm \
  modules/YaPI/HTTPD.pm

module2dir = @moduledir@/YaST
module2_DATA = \
  modules/YaST/HTTPDData.pm \
  modules/YaST/HTTPDPhpModule.pm \
  modules/YaST/httpdUtils.pm

client_DATA = \
  clients/http-server_auto.rb \
  clients/http-server.rb

yncludedir = @yncludedir@/http-server
ynclude_DATA = \
  include/http-server/wizard-dialog.rb \
  include/http-server/wizards.rb \
  include/http-server/dialogs.rb \
  include/http-server/complex.rb \
  include/http-server/routines.rb \
  include/http-server/helps.rb

scrconf_DATA = \
  scrconf/cfg_http_server.scr

agent_SCRIPTS = \
  servers_non_y2/ag_http_server

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/http-server.rnc

desktop_DATA = \
  desktop/http-server.desktop

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-http-server-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-http-server.svg

EXTRA_DIST = $(module_DATA) $(module1_DATA) $(module2_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(agent_SCRIPTS) $(schemafiles_DATA) $(desktop_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
