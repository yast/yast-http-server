# encoding: utf-8

# File:	clients/http-server.ycp
# Package:	Configuration of http-server
# Summary:	Main file
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#
# Main file for http-server configuration. Uses all other files.
module Yast
  class HttpServerClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of the http-server</h3>

      textdomain "http-server"

      Yast.import "CommandLine"
      Yast.import "YaPI::HTTPD"
      Yast.import "Popup"
      Yast.import "Report"
      Yast.import "Message"
      Yast.import "Hostname"
      Yast.import "HttpServerWidgets"
      Yast.import "HttpServer"
      Yast.import "YaST::HTTPDData"

      Yast.include self, "http-server/wizards.rb"


      @cmdline_description = {
        "id"         => "http-server",
        # translators: command line help for HTTP server module
        "help"       => _(
          "Configuration of HTTP server (Apache2)"
        ),
        "guihandler" => fun_ref(method(:HttpServerSequence), "boolean ()"),
        "initialize" => fun_ref(HttpServer.method(:Read), "boolean ()"),
        "finish"     => fun_ref(HttpServer.method(:Write), "boolean ()"),
        "actions"    => {
          "configure" => {
            # translators: help text for configure command line action
            "help"    => _(
              "Configure host settings"
            ),
            "handler" => fun_ref(
              method(:ConfigureHandler),
              "boolean (map <string, any>)"
            )
          },
          "modules"   => {
            # translators: help text for modules command line action
            "help"    => _(
              "Configure the Apache2 server modules"
            ),
            "handler" => fun_ref(
              method(:ModulesHandler),
              "boolean (map <string, string>)"
            )
          },
          "listen"    => {
            # translators: help text for listen command line action
            "help"    => _(
              "Set up the ports and network addresses where the server should listen."
            ),
            "handler" => fun_ref(
              method(:ListenHandler),
              "boolean (map <string, string>)"
            )
          },
          "hosts"     => {
            "help"    => _("Configure virtual hosts"),
            "handler" => fun_ref(
              method(:HostsHandler),
              "boolean (map <string, string>)"
            )
          },
          "mode"      => {
            "help"    => _("Enable or disable wizard mode."),
            "handler" => fun_ref(
              method(:ModeHandler),
              "boolean (map <string, string>)"
            )
          }
        },
        "options"    => {
          "servername"   => {
            "type" => "fullhostname",
            # translators: help text for servername option (configure command line action)
            "help" => _(
              "Server name, for example, www.example.com"
            )
          },
          "serveradmin"  => {
            "type" => "string",
            # translators: help text for serveradmin option (configure command line action)
            "help" => _(
              "E-mail address of the server administrator"
            )
          },
          "documentroot" => {
            "type" => "string",
            # translators: help text for documentroot option (configure command line action)
            "help" => _(
              "Directory where the documents of the server are stored"
            )
          },
          "host"         => {
            "type" => "string",
            # translators: help text for host option (configure command line action)
            "help" => _(
              "Name of the host to configure."
            )
          },
          "add"          => {
            "type"     => "regex",
            "typespec" => "([[0-9a-f:]+]:[0-9]+)|([0-9]+)|([0-9]+.[0-9]+.[0-9]+.[0-9]+.[0-9]+)",
            # translators: help text for add subcommand (listen command line action)
            "help"     => _(
              "Add a new listen entry ([address:]port)"
            )
          },
          "delete"       => {
            "type"     => "regex",
            "typespec" => "([[0-9a-f:]+]:[0-9]+)|([0-9]+)|([0-9]+.[0-9]+.[0-9]+.[0-9]+.[0-9]+)",
            # translators: help text for delete subcommand (listen command line action)
            "help"     => _(
              "Delete an existing listen entry ([address:]port)"
            )
          },
          "list"         => {
            # translators: help text for list subcommand (listen command line action)
            "help" => _(
              "List configured entries"
            )
          },
          "enable"       => {
            "type"     => "regex",
            "typespec" => ".+(,.+)*",
            # translators: help text for enable subcommand (modules command line action)
            "help"     => _(
              "Comma-separated list of modules to enable"
            )
          },
          "disable"      => {
            "type"     => "regex",
            "typespec" => ".+(,.+)*",
            # translators: help text for disable subcommand (modules command line action)
            "help"     => _(
              "Comma-separated list of modules to disable"
            )
          },
          "create"       => { "help" => _("Create new virtual host") },
          "remove"       => {
            "type" => "string",
            "help" => _("Delete existing virtual host")
          },
          "setdefault"   => {
            "type" => "string",
            "help" => _("Set selected virtual host as default host")
          },
          "wizard"       => {
            "type" => "string",
            "help" => _("Set wizard mode \"on\" or \"off\".")
          }
        },
        "mappings"   => {
          "configure" => [
            "host",
            "servername",
            "serveradmin",
            "documentroot",
            "list"
          ],
          "modules"   => ["enable", "disable", "list"],
          "listen"    => ["add", "delete", "list"],
          "hosts"     => [
            "create",
            "servername",
            "serveradmin",
            "documentroot",
            "remove",
            "setdefault",
            "list"
          ],
          "mode"      => ["wizard"]
        }
      }


      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("HttpServer module started")


      # is this proposal or not?
      @propose = false
      @args = WFM.Args
      if Ops.greater_than(Builtins.size(@args), 0)
        if Ops.is_path?(WFM.Args(0)) && WFM.Args(0) == path(".propose")
          Builtins.y2milestone("Using PROPOSE mode")
          @propose = true
        end
      end

      # main ui function
      @ret = nil

      if @propose
        @ret = HttpServerAutoSequence()
      else
        @ret = CommandLine.Run(@cmdline_description)
      end
      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("HttpServer module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end

    # Handler for command line action "configure".
    #
    # @param [Hash{String => Object}] options    map of the options provided on the command line
    # @return [Boolean]   true on success
    def ConfigureHandler(options)
      options = deep_copy(options)
      hosts = YaST::HTTPDData.GetHostsList

      if !Builtins.contains(hosts, Ops.get_string(options, "host", ""))
        if !Builtins.haskey(options, "host")
          # translators: error message in configure command line action
          Report.Error(_("Configured host not specified"))
        else
          # translators: error message in configure command line action
          Report.Error(
            _("Only existing hosts can be specified as the host to configure")
          )
        end
        return false
      end

      host = Ops.get_string(options, "host", "")
      hostconfig = YaPI::HTTPD.GetHost(host)
      if Builtins.haskey(options, "list")
        CommandLine.Print(
          Builtins.sformat(
            "ServerName: %1",
            HttpServerWidgets.get_host_value("ServerName", hostconfig, "")
          )
        )
        CommandLine.Print(
          Builtins.sformat(
            "ServerAdmin: %1",
            HttpServerWidgets.get_host_value("ServerAdmin", hostconfig, "")
          )
        )
        CommandLine.Print(
          Builtins.sformat(
            "DocumentRoot: %1",
            HttpServerWidgets.get_host_value("DocumentRoot", hostconfig, "")
          )
        )
        return true
      end

      value = Ops.get_string(options, "servername", "")
      if value != ""
        if !Hostname.CheckFQ(value)
          Report.Error(_("Invalid server name."))
          return false
        end
        hostconfig = HttpServerWidgets.set_host_value(
          "ServerName",
          hostconfig,
          value
        )
      end

      value = Ops.get_string(options, "serveradmin", "")
      if value != ""
        if !Builtins.regexpmatch(value, ".+@.+")
          Report.Error(_("Invalid server admin."))
          return false
        end
        hostconfig = HttpServerWidgets.set_host_value(
          "ServerAdmin",
          hostconfig,
          value
        )
      end

      value = Ops.get_string(options, "documentroot", "")
      if value != ""
        hostconfig = HttpServerWidgets.set_host_value(
          "DocumentRoot",
          hostconfig,
          value
        )
      end

      if !HttpServerWidgets.validate_server(
          Ops.get_string(options, "servername", ""),
          hostconfig
        )
        Report.Error(_("Validate error "))
        return false
      end

      YaPI::HTTPD.ModifyHost(host, hostconfig)

      true
    end

    # Handler for command line action "modules".
    #
    # @param [Hash{String => String}] options    map of the options provided on the command line
    # @return [Boolean]   true on success
    def ModulesHandler(options)
      options = deep_copy(options)
      # check the command to be present exactly once
      command = CommandLine.UniqueOption(options, ["enable", "disable", "list"])
      return false if command == nil

      if command == "enable"
        mods = Builtins.splitstring(Ops.get(options, "enable", ""), ",")
        YaPI::HTTPD.ModifyModuleList(mods, true)
      elsif command == "disable"
        mods = Builtins.splitstring(Ops.get(options, "disable", ""), ",")
        YaPI::HTTPD.ModifyModuleList(mods, false)
      elsif command == "list"
        # translators: heading for the "modules list" command line action output
        # please, try to align the texts if possible.
        CommandLine.Print(_("Status \tModule\n=================="))

        enabled = YaPI::HTTPD.GetModuleList

        Builtins.foreach(YaPI::HTTPD.GetKnownModules) do |mod|
          # translators: status of a module
          CommandLine.Print(
            Builtins.sformat(
              "%1\t%2",
              # translators: server module status
              Builtins.contains(enabled, Ops.get_string(mod, "name", "")) ?
                _("Enabled") :
                # translators: server module status
                _("Disabled"),
              Ops.get_locale(mod, "name", _("unknown"))
            )
          )
        end
      end

      true
    end

    # Handler for command line action "listen".
    #
    # @param [Hash{String => String}] options    map of the options provided on the command line
    # @return [Boolean]   true on success
    def ListenHandler(options)
      options = deep_copy(options)
      # check the command to be present exactly once
      command = CommandLine.UniqueOption(options, ["add", "delete", "list"])
      all_listens = YaST::HTTPDData.GetCurrentListen
      if command == nil
        return false
      elsif command == "list"
        # translators: heading for the "listen list" command line action output
        # please, try to align the texts if possible.
        CommandLine.Print(_("Listen Statements:"))
        CommandLine.Print("==================")
        Builtins.foreach(all_listens) do |listen|
          CommandLine.Print(
            Builtins.sformat(
              "%1:%2",
              Ops.get_locale(listen, "ADDRESS", _("All interfaces")),
              Ops.get_string(listen, "PORT", "80")
            )
          )
        end
        return true
      end

      address = ""
      port = ""
      listens = Builtins.splitstring(Ops.get(options, command, ""), ":")
      if Builtins.size(listens) == 1
        port = Ops.get_string(listens, 0, "")
      elsif Builtins.size(listens) == 2
        address = Ops.get_string(listens, 0, "")
        port = Ops.get_string(listens, 1, "")
      else
        return false
      end

      finded = false
      Builtins.foreach(all_listens) do |listen|
        if Ops.get_string(listen, "ADDRESS", "") == address &&
            Ops.get_string(listen, "PORT", "") == port
          finded = true
        end
      end

      if command == "add"
        #FIXME:  check, if new address and port are correct values (if address is from machine's interfaces)
        if Ops.greater_than(Builtins.size(address), 0) &&
            !Builtins.contains(Builtins.maplist(HttpServer.ip2device) do |ip, dev|
              ip
            end, address)
          Report.Error(_("Can use only existing interfaces"))
          return false
        end
        if finded
          # translators: error message in "listen add" command line action
          Report.Error(
            Builtins.sformat(
              _("The listen statement '%1' is already configured."),
              Ops.get(options, "add", "")
            )
          )
          return false
        end
        YaST::HTTPDData.CreateListen(
          Builtins.tointeger(port),
          Builtins.tointeger(port),
          address
        )
        HttpServer.modified = true
      elsif command == "delete"
        if !finded
          # translators: error message in "listen delete" command line action
          Report.Error(_("Can remove only existing listeners"))
          return false
        end
        YaST::HTTPDData.DeleteListen(
          Builtins.tointeger(port),
          Builtins.tointeger(port),
          address
        )
        HttpServer.modified = true
      end
      true
    end

    # Handling hosts dialog
    # @param [Hash{String => String}] options map to handle
    # @return [Boolean] correct execution
    def HostsHandler(options)
      options = deep_copy(options)
      # check the command to be present exactly once
      hosts = YaST::HTTPDData.GetHostsList

      if Builtins.haskey(options, "list")
        CommandLine.Print(_("Hosts list:"))
        CommandLine.Print("==================")
        Builtins.foreach(hosts) { |host| CommandLine.Print(host) }
        return true
      end

      # create
      if Builtins.haskey(options, "create")
        if !(Builtins.haskey(options, "servername") &&
            Builtins.haskey(options, "serveradmin") &&
            Builtins.haskey(options, "documentroot"))
          Report.Error(_("Some parameter missing"))
          return false
        end
        hostmap = [
          {
            "KEY"   => "ServerName",
            "VALUE" => Ops.get(options, "servername", "")
          },
          {
            "KEY"   => "ServerAdmin",
            "VALUE" => Ops.get(options, "serveradmin", "")
          },
          {
            "KEY"   => "DocumentRoot",
            "VALUE" => Ops.get(options, "documentroot", "")
          },
          { "KEY" => "VirtualByName", "VALUE" => "1" },
          { "KEY" => "SSL", "VALUE" => "0" },
          {
            "KEY"   => "HostIP",
            "VALUE" => Ops.get(Builtins.maplist(HttpServer.ip2device) do |ip, dev|
              ip
            end, 0)
          }
        ]
        if !HttpServerWidgets.validate_server(
            Ops.get(options, "servername", ""),
            hostmap
          )
          Report.Error(_("Validate error "))
          return false
        end

        YaST::HTTPDData.CreateHost(
          Ops.add(
            Ops.add(Ops.get(Builtins.maplist(HttpServer.ip2device) { |ip, dev| ip }, 0, ""), "/"),
            Ops.get(options, "servername", "")
          ),
          hostmap
        )

        return false if hostmap == nil
        HttpServer.modified = true
        return true
      end
      # remove and setdefault

      if !Builtins.contains(hosts, Ops.get(options, "remove", "")) &&
          !Builtins.contains(hosts, Ops.get(options, "setdefault", ""))
        Report.Error(_("Argument can be only existing host"))
        return false
      end

      if Builtins.haskey(options, "setdefault")
        if Ops.get(options, "setdefault", "") == "default"
          Report.Error(_("The host is already default."))
          return false
        else
          CommandLine.Print("Will set default host")
          host = Ops.get(options, "setdefault", "")
          Builtins.y2milestone("Changing default host to '%1'", host)

          defhost_options = YaST::HTTPDData.GetHost("default")
          servername = Convert.to_string(
            HttpServerWidgets.get_host_value("ServerName", defhost_options, "")
          )
          ip = Convert.to_string(
            HttpServerWidgets.get_host_value("HostIP", defhost_options, "")
          )

          # move the old default host elsewhere
          YaST::HTTPDData.CreateHost(
            Ops.add(Ops.add(ip, "/"), servername),
            defhost_options
          )
          #      YaST::HTTPDData::CreateHost ( res["ip"]:ip + "/" + res["name"]:ip, defhost_options );
          # replace the values of the default host by the new one
          YaST::HTTPDData.ModifyHost("default", YaST::HTTPDData.GetHost(host))
          # remove the old non-default host
          YaST::HTTPDData.DeleteHost(host)

          HttpServer.modified = true

          return true
        end
      end

      if Ops.get(options, "remove", "") == "default"
        Report.Error(_("Cannot delete the default host."))
        return false
      else
        YaST::HTTPDData.DeleteHost(Ops.get(options, "remove", ""))
      end

      true
    end

    def ModeHandler(options)
      options = deep_copy(options)
      Builtins.y2internal("options %1", options)
      mode = Ops.get(options, "wizard", "")
      Builtins.y2internal("mode %1", mode)
      if Ops.greater_than(Builtins.size(mode), 0)
        if mode == "on" || mode == "true"
          HttpServer.setWizardMode(true)
        else
          HttpServer.setWizardMode(false)
        end
      end
      true
    end
  end
end

Yast::HttpServerClient.new.main
