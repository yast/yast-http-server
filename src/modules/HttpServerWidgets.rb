# encoding: utf-8

# File:	modules/HttpServerWidgets.ycp
# Package:	Configuration of http-server
# Summary:	Widgets used by HTTP server configuration
# Authors:	Jiri Srain <jsrain@suse.cz>
#		Stanislav Visnovsky <visnov@suse.cz>
# Internal
#
# $Id$
require "yast"

module Yast
  class HttpServerWidgetsClass < Module
    def main
      Yast.import "UI"

      textdomain "http-server"

      Yast.import "Directory"
      Yast.import "Mode"
      Yast.import "IP"
      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Report"
      Yast.import "Service"
      Yast.import "String"
      Yast.import "LogView"
      Yast.import "TablePopup"
      Yast.import "HttpServer"
      Yast.import "YaST::HTTPDData"
      Yast.import "Confirm"
      Yast.import "CWMServiceStart"
      Yast.import "CWMFirewallInterfaces"
      Yast.import "Punycode"
      Yast.import "Package"
      Yast.import "DnsServerAPI"
      Yast.import "FileUtils"
      Yast.import "Hostname"
      Yast.import "DNS"
      Yast.import "Arch"
      Yast.import "PackageSystem"
      Yast.import "Map"

      Yast.include self, "http-server/helps.rb"

      @currenthost = "main"
      @dir_value = ""
      @init_tab = "listen"

      @update_contents = false
      @vhost_descr = []

      @overview_widget = {
        "widget"        => :custom,
        "custom_widget" => VBox(
          Mode.config ?
            VSpacing(0) :
            # menu button label
            MenuButton(
              Id(:menu),
              _("&Log Files"),
              # menu button item
              [
                Item(Id(:show_access_log), _("Show &Access Log")),
                # menu button item
                Item(Id(:show_error_log), _("Show &Error Log"))
              ]
            )
        ),
        #    "init"		:  OverviewInit,
        "handle"        => fun_ref(
          method(:OverviewHandle),
          "symbol (string, map)"
        ),
        "help"          => Ops.get_string(@HELPS, "overview_widget", "")
      }

      @hosts_widget = TablePopup.CreateTableDescr(
        {
          "add_delete_buttons" => true,
          "up_down_buttons"    => false,
          "unique_keys"        => true,
          "changed_column"     => true
        },
        {
          "init"          => fun_ref(method(:HostsInit), "void (string)"),
          "handle"        => fun_ref(
            method(:HostsHandle),
            "symbol (string, map)"
          ),
          "ids"           => fun_ref(method(:HostsContents), "list (map)"),
          "option_delete" => fun_ref(
            method(:HostsDelete),
            "boolean (any, string)"
          ),
          "help"          => Ops.get_string(@HELPS, "hosts", ""),
          "fallback"      => {
            "summary"    => fun_ref(
              method(:HostDocumentRootSummary),
              "string (any, string)"
            ),
            "changed"    => fun_ref(
              method(:HostIsDefault),
              "boolean (any, string)"
            ),
            "label_func" => fun_ref(method(:HostName), "string (any, string)")
          }
        }
      )


      @mode_replace_point_key = "replace_point"

      # Map of popups for CWM
      @popups = {
        "ServerName"    => {
          "table" => {
            # table cell description
            "label"    => _("Server Name"),
            "optional" => false,
            "unique"   => true
          },
          "popup" => {
            # table cell description
            "label"  => _("Server Name"),
            "widget" => :textentry
          }
        },
        "DocumentRoot"  => {
          "table" => {
            # table cell description
            "label"    => _("Document Root"),
            "optional" => false,
            "unique"   => true
          },
          "popup" => { "widget" => :textentry }
        },
        "ServerAdmin"   => {
          "table" => {
            # table cell description
            "label"    => _(
              "Server Administrator E-Mail"
            ),
            "optional" => false,
            "unique"   => true
          },
          "popup" => { "widget" => :textentry }
        },
        "VirtualByName" => {
          "table" => {
            # table cell description
            "label"    => _("Server Resolution"),
            "optional" => false,
            "unique"   => true
          },
          "popup" => {
            "widget" => :radio_buttons,
            "items"  => [
              # translators: radio button for name-based virtual hosts
              ["1", _("Determine Request Server by HTTP &Headers")],
              # translators: radio button for IP-based virtual hosts
              ["0", _("Determine Request Server by Server IP &Address")]
            ]
          }
        },
        "HostIP"        => {
          "table" => {
            # table cell description
            "label"    => _("IP Address"),
            "optional" => false,
            "unique"   => true
          }
        },
        "SSL"           => {
          "table" => { "handle" => :ssl, "optional" => false, "unique" => true }
        },
        "Directory"     => {
          "table" => { "handle" => :dir, "optional" => true, "unique" => true }
        }
      }

      @hostwidget = TablePopup.CreateTableDescr(
        {
          "add_delete_buttons" => true,
          "up_down_buttons"    => false,
          "unique_keys"        => false
        },
        {
          "init"              => fun_ref(method(:HostInit), "void (string)"),
          "handle"            => fun_ref(
            method(:handleHostTable),
            "symbol (string, map)"
          ),
          "store"             => fun_ref(
            method(:HostStore),
            "void (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validate_server_fnc),
            "boolean (string, map)"
          ),
          "options"           => getHostOptions(false),
          "ids"               => fun_ref(
            method(:HostTableContents),
            "list (map)"
          ),
          "id2key"            => fun_ref(
            method(:HostId2Key),
            "string (map, any)"
          ),
          "fallback"          => {
            "init"    => fun_ref(
              method(:DefaultHostPopupInit),
              "void (any, string)"
            ),
            "store"   => fun_ref(
              method(:DefaultHostPopupStore),
              "void (any, string)"
            ),
            "summary" => fun_ref(
              method(:HostTableEntrySummary),
              "string (any, string)"
            )
          },
          "option_delete"     => fun_ref(
            method(:HostTableEntryDelete),
            "boolean (any, string)"
          ),
          "add_items"         => Builtins.maplist(
            Convert.convert(
              getHostOptions(false),
              :from => "map",
              :to   => "map <string, any>"
            )
          ) { |key, value| key },
          "help"              => Ops.get_string(@HELPS, "global_table", "")
        }
      )

      @host_options = nil

      @sslwidget = TablePopup.CreateTableDescr(
        {
          "add_delete_buttons" => true,
          "up_down_buttons"    => false,
          "unique_keys"        => true
        },
        {
          "init"          => fun_ref(method(:SSLInit), "void (string)"),
          "handle"        => fun_ref(
            method(:handleSSLTable),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(method(:SSLStore), "void (string, map)"),
          "options"       => Convert.convert(
            getSSLOptions,
            :from => "map",
            :to   => "map <string, any>"
          ),
          "ids"           => fun_ref(method(:SSLTableContents), "list (map)"),
          "id2key"        => fun_ref(method(:HostId2Key), "string (map, any)"),
          "fallback"      => {
            "init"    => fun_ref(
              method(:DefaultHostPopupInit),
              "void (any, string)"
            ),
            "store"   => fun_ref(
              method(:DefaultHostPopupStore),
              "void (any, string)"
            ),
            "summary" => fun_ref(
              method(:HostTableEntrySummary),
              "string (any, string)"
            )
          },
          "option_delete" => fun_ref(
            method(:HostTableEntryDelete),
            "boolean (any, string)"
          ),
          "add_items"     => Builtins.maplist(
            Convert.convert(
              getSSLOptions,
              :from => "map",
              :to   => "map <string, any>"
            )
          ) { |key, value| key },
          "help"          => Ops.get_string(@HELPS, "ssl", "")
        }
      )


      @dirwidget = TablePopup.CreateTableDescr(
        {
          "add_delete_buttons" => true,
          "up_down_buttons"    => false,
          "unique_keys"        => true
        },
        {
          "init"          => fun_ref(method(:DirInit), "void (string)"),
          "handle"        => fun_ref(
            method(:handleDirTable),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(method(:DirStore), "void (string, map)"),
          "options"       => Convert.convert(
            getDirOptions,
            :from => "map",
            :to   => "map <string, any>"
          ),
          "ids"           => fun_ref(method(:DirTableContents), "list (map)"),
          "id2key"        => fun_ref(method(:HostId2Key), "string (map, any)"),
          "fallback"      => {
            "init"    => fun_ref(method(:DirPopupInit), "void (any, string)"),
            "store"   => fun_ref(
              method(:DefaultHostPopupStore),
              "void (any, string)"
            ),
            "summary" => fun_ref(
              method(:HostTableEntrySummary),
              "string (any, string)"
            )
          },
          "option_delete" => fun_ref(
            method(:HostTableEntryDelete),
            "boolean (any, string)"
          ),
          "add_items"     => Builtins.maplist(
            Convert.convert(
              getDirOptions,
              :from => "map",
              :to   => "map <string, any>"
            )
          ) { |key, value| key },
          "help"          => Ops.get_string(@HELPS, "dir", "")
        }
      )

      @dns_zone = ""



      # Map of widgets for CWM
      @widgets = {
        "server_enable"     => {
          "widget"        => :radio_buttons,
          # translator: server enable/disable radio button group
          "label"         => _(
            "HTTP &Service"
          ),
          "items"         => [
            # translators: service status radio button label
            ["disabled", _("Disabled")],
            # translators: service status radio button label
            ["enabled", _("Enabled")]
          ],
          "init"          => fun_ref(
            method(:initServiceStatus),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:handleServiceStatus),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(
            method(:storeServiceStatus),
            "void (string, map)"
          ),
          "handle_events" => ["enabled", "disabled"],
          "opt"           => [:notify],
          "help"          => @HELPS["server_enable"]
        },
        "firewall_adapt"    => CWMFirewallInterfaces.CreateOpenFirewallWidget(
          {
            # Firewalld already defines the http and https services. This
            # module modifies the service adding custom ports, taking that in
            # account we will continue using apache2 and apache2-ssl.
            "services"        => ["apache2", "apache2-ssl"],
            "help"            => @HELPS["firewall_adapt"],
            "display_details" => true
          }
        ),
        "host"              => @hostwidget,
        "LISTEN"            => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            # translators: radio button group label
            Left(Label(_("Listen on Ports:"))),
            Table(
              Id(:listen),
              Header(
                # table header
                _("Network Address"),
                # table header
                _("Port")
              ),
              []
            ),
            HBox(
              PushButton(Id(:add), Opt(:key_F3), Label.AddButton),
              PushButton(Id(:edit), Opt(:key_F4), Label.EditButton),
              PushButton(Id(:delete), Opt(:key_F5), Label.DeleteButton),
              HStretch()
            )
          ),
          "init"          => fun_ref(
            method(:initListenSettings),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:handleListenSettings),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "listen", "")
        },
        "MODULES"           => {
          "widget"            => :custom,
          "custom_widget"     => VBox(
            Table(
              Id(:modules),
              Header(
                # table header: module name
                _("Name"),
                # table header: module status
                _("Status") + "    ",
                # table header: module description
                _("Description")
              ),
              []
            ),
            HBox(
              PushButton(
                Id(:toggle),
                # translators: toggle button label
                _("&Toggle Status")
              ),
              HStretch(),
              PushButton(
                Id(:add_user),
                # translators: add user-defined module button label
                _("&Add Module")
              )
            )
          ),
          "init"              => fun_ref(method(:initModules), "void (string)"),
          "handle"            => fun_ref(
            method(:handleModules),
            "symbol (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateModules),
            "boolean (string, map)"
          ),
          "help"              => Ops.get_string(@HELPS, "modules", "")
        },
        "MAIN_HOST"         => TablePopup.CreateTableDescr(
          {
            "add_delete_buttons" => true,
            "up_down_buttons"    => false,
            "unique_keys"        => false
          },
          {
            "init"              => fun_ref(method(:HostInit), "void (string)"),
            "handle"            => fun_ref(
              method(:handleHostTable),
              "symbol (string, map)"
            ),
            "store"             => fun_ref(
              method(:HostStore),
              "void (string, map)"
            ),
            "validate_type"     => :function,
            "validate_function" => fun_ref(
              method(:validate_server_fnc),
              "boolean (string, map)"
            ),
            "options"           => getHostOptions(true),
            "ids"               => fun_ref(
              method(:HostTableContents),
              "list (map)"
            ),
            "id2key"            => fun_ref(
              method(:HostId2Key),
              "string (map, any)"
            ),
            "fallback"          => {
              "init"    => fun_ref(
                method(:DefaultHostPopupInit),
                "void (any, string)"
              ),
              "store"   => fun_ref(
                method(:DefaultHostPopupStore),
                "void (any, string)"
              ),
              "summary" => fun_ref(
                method(:HostTableEntrySummary),
                "string (any, string)"
              )
            },
            "option_delete"     => fun_ref(
              method(:HostTableEntryDelete),
              "boolean (any, string)"
            ),
            "add_items"         => Builtins.maplist(
              Convert.convert(
                getHostOptions(true),
                :from => "map",
                :to   => "map <string, any>"
              )
            ) { |key, value| key },
            "help"              => Ops.get_string(@HELPS, "global_table", "")
          }
        ),
        "HOSTS"             => TablePopup.CreateTableDescr(
          {
            "add_delete_buttons" => true,
            "up_down_buttons"    => false,
            "unique_keys"        => true,
            "changed_column"     => true
          },
          {
            "init"          => fun_ref(method(:HostsInit), "void (string)"),
            "handle"        => fun_ref(
              method(:HostsHandle),
              "symbol (string, map)"
            ),
            "ids"           => fun_ref(method(:HostsContents), "list (map)"),
            "option_delete" => fun_ref(
              method(:HostsDelete),
              "boolean (any, string)"
            ),
            "help"          => Ops.get_string(@HELPS, "hosts", ""),
            "fallback"      => {
              "summary"    => fun_ref(
                method(:HostDocumentRootSummary),
                "string (any, string)"
              ),
              "changed"    => fun_ref(
                method(:HostIsDefault),
                "boolean (any, string)"
              ),
              "label_func" => fun_ref(method(:HostName), "string (any, string)")
            }
          }
        ),
        "logs"              => @overview_widget,
        "hosts"             => @hosts_widget,
        "ssl"               => @sslwidget,
        "dir"               => @dirwidget,
        "dir_name"          => {
          "widget"        => :custom,
          "custom_widget" => VBox(TextEntry(Id(:dir_name), _("Directory")))
        },
        # wizard widgets
        "open_port"         => {
          "widget"            => :textentry,
          # translators: text entry
          "label"             => _("&Port:"),
          "init"              => fun_ref(method(:initOpenPort), "void (string)"),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateOpenPort),
            "boolean (string, map)"
          ),
          "help"              => Ops.get_string(@HELPS, "open_port", "")
        },
        "listen_interfaces" => {
          "widget"            => :custom,
          # translators: multi selection box
          "custom_widget"     => ReplacePoint(
            Id(@mode_replace_point_key),
            MultiSelectionBox(_("&Listen on Interfaces"), [])
          ),
          "init"              => fun_ref(
            method(:initListenInterfaces),
            "void (string)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateListenInterfaces),
            "boolean (string, map)"
          ),
          "help"              => Ops.get_string(@HELPS, "listen_interfaces", "")
        },
        "booting"           => CWMServiceStart.CreateAutoStartWidget(
          {
            "get_service_auto_start" => fun_ref(
              method(:getServiceAutoStart),
              "boolean ()"
            ),
            "set_service_auto_start" => fun_ref(
              method(:setServiceAutoStart),
              "void (boolean)"
            ),
            #translators: radiobutton - to start Apache2 service automatically
            "start_auto_button"      => _(
              "Start Apache2 Server When Booting"
            ),
            #translators: radiobutton - to don't start Apache2 service
            "start_manual_button"    => _(
              "Start Apache2 Server Manually"
            )
          }
        ),
        "expert_conf"       => {
          "widget" => :push_button,
          #translators: button to enter expert configuration
          "label"  => _(
            "&HTTP Server Expert Configuration..."
          ),
          #		"init"	 : initExpertConf,
          "handle" => fun_ref(
            method(:handleExpertConf),
            "symbol (string, map)"
          ),
          "help"   => Ops.get_string(@HELPS, "expert_conf", "")
        },
        "script_modules"    => {
          "widget"        => :custom,
          "custom_widget" => ReplacePoint(Id(:scr_mod_replace), Label("")),
          "init"          => fun_ref(
            method(:initScriptModules),
            "void (string)"
          ),
          "help"          => Ops.get_string(@HELPS, "script_modules", "")
        },
        "vhost_id"          => {
          "widget"            => :custom,
          "custom_widget"     => Frame(
            # translators: frame title for new hsot identification details
            _("Server Identification"),
            VBox(
              # translators: textentry, new host server name
              TextEntry(Id(:servername), _("Server &Name:")),
              HBox(
                # translators: textentry, document root for the new host
                TextEntry(Id(:documentroot), _("Server &Contents Root:")),
                VBox(Label(""), PushButton(Id(:browse), Label.BrowseButton))
              ),
              # translators: textentry, administrator's e-mail for the new host
              TextEntry(Id(:admin), _("&Administrator E-Mail:"))
            )
          ),
          "help"              => Ops.get_string(@HELPS, "vhost_id", ""),
          "init"              => fun_ref(method(:initVhostId), "void (string)"),
          "handle"            => fun_ref(
            method(:handleVhostId),
            "symbol (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateVhostId),
            "boolean (string, map)"
          ),
          "store"             => fun_ref(
            method(:storeVhostId),
            "void (string, map)"
          )
        },
        "vhost_res"         => {
          "widget"            => :custom,
          "custom_widget"     => Frame(
            # translators: frame title for method of incoming request resolution
            _("Server Resolution"),
            HBox(
              VBox(
                # translators: IP address for the new host
                Left(TextEntry(Id(:virtual_host), _("VirtualHost"))),
                Left(PushButton(Id(:change_vhost), _("Change VirtualHost ID")))
              ),
              RadioButtonGroup(
                Id(:resolution),
                VBox(
                  # translators: radio button for name-based virtual hosts
                  Left(
                    RadioButton(
                      Id(:name_based),
                      Opt(:notify),
                      _("Determine Request Server by HTTP &Headers"),
                      true
                    )
                  ),
                  # translators: radio button for IP-based virtual hosts
                  Left(
                    RadioButton(
                      Id(:ip_based),
                      Opt(:notify),
                      _("Determine Request Server by Server IP &Address")
                    )
                  )
                )
              )
            )
          ),
          "init"              => fun_ref(method(:initVhostRes), "void (string)"),
          "handle"            => fun_ref(
            method(:handleVhostRest),
            "symbol (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateVhostRes),
            "boolean (string, map)"
          ),
          "help"              => Ops.get_string(@HELPS, "vhost_res", "")
        },
        "vhost_details"     => {
          "widget"        => :custom,
          "custom_widget" => HBox(
            HSpacing(0.5),
            VBox(
              ReplacePoint(Id(:replace), Empty()),
              VSpacing(1),
              Frame(
                # translators: frame title for virtual host identification details
                _("CGI Options"),
                VBox(
                  Left(
                    CheckBox(
                      Id(:cgi_support),
                      Opt(:notify),
                      _("Enable &CGI for This Virtual Host")
                    )
                  ),
                  HBox(
                    # translators: textentry, certificate file path
                    TextEntry(Id(:cgi_dir), _("CGI &Directory Path")),
                    VBox(
                      Label(""),
                      PushButton(Id(:browse_cgi_dir), Label.BrowseButton)
                    )
                  )
                )
              ),
              VSpacing(1),
              Frame(
                _("SSL Support"),
                VBox(
                  Left(
                    CheckBox(
                      Id(:ssl_support),
                      Opt(:notify),
                      _("Enable &SSL Support for This Virtual Host")
                    )
                  ),
                  VBox(
                    # translators: textentry, certificate file path
                    HBox(
                      Label(""),
                      TextEntry(Id(:certfile), _("&Certificate File Path")),
                      PushButton(Id(:browse_cert), Label.BrowseButton)
                    ),
                    HBox(
                      Label(""),
                      TextEntry(Id(:keyfile), _("&Certificate Key File Path")),
                      PushButton(Id(:browse_key), Label.BrowseButton)
                    )
                  )
                )
              ),
              VSpacing(1),
              Frame(
                _("Directory Options"),
                Left(TextEntry(Id(:dir_index), _("&Directory Index")))
              ),
              VSpacing(1),
              Frame(
                _("Public HTML"),
                Left(CheckBox(Id(:pub_html), _("Enable &Public HTML")))
              )
            )
          ),
          "init"          => fun_ref(method(:initVhostDetails), "void (string)"),
          "handle"        => fun_ref(
            method(:handleVhostDetails),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(
            method(:storeVhostDetails),
            "void (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "vhost_details", "")
        },
        "summary_text"      => {
          "widget"        => :custom,
          "custom_widget" => ReplacePoint(Id(:summary_text_rp), RichText("")),
          "init"          => fun_ref(method(:initSummaryText), "void (string)"),
          "help"          => Ops.get_string(@HELPS, "summary_text", "")
        }
      }

      # *************************************** log popups **************************


      # ************************************ default host table ********************

      @option_counter = 0
      @deleted_options = []

      # these are for future use:

      # error message - the entered ip address is not found
      @__nonconfigured_ipaddress = _(
        "The IP address is not configured\non this machine."
      )
    end

    # Validate certificate
    # @return [Boolean] certificate valid
    def CheckCommonServerCertificate
      s = Convert.to_integer(
        SCR.Read(path(".target.size"), "/etc/ssl/servercerts/servercert.pem")
      )
      return false if Ops.less_or_equal(s, 0)
      s = Convert.to_integer(
        SCR.Read(path(".target.size"), "/etc/ssl/servercerts/serverkey.pem")
      )
      return false if Ops.less_or_equal(s, 0)
      true
    end

    # Get host value
    # @param [String] keyword string
    # @param [Array<Hash{String => Object>}] host list< map<string, any> >
    # @param [Object] defaultvalue any
    # @return [Object] host value
    def get_host_value(keyword, host, defaultvalue)
      host = deep_copy(host)
      defaultvalue = deep_copy(defaultvalue)
      res = deep_copy(defaultvalue)

      Builtins.foreach(host) do |option|
        if Ops.get(option, "KEY") == keyword
          res = Ops.get(option, "VALUE", defaultvalue)
          raise Break
        end
      end

      # drop quotes, if exist
      if Ops.is_string?(res)
        res = Builtins.regexpsub(
          Convert.to_string(res),
          "\"?([^\"]*)\"?",
          "\\1"
        )
      end

      deep_copy(res)
    end

    # Set host value
    # @param [String] keyword string
    # @param [Array<Hash{String => Object>}] host list< map<string, any> >
    # @param [Object] value any
    # @return [Array< Hash{String => Object>}] host map
    def set_host_value(keyword, host, value)
      host = deep_copy(host)
      value = deep_copy(value)
      index = 0
      Builtins.foreach(host) do |option|
        raise Break if Ops.get(option, "KEY") == keyword
        index = Ops.add(index, 1)
      end

      # adding a new option
      if Ops.greater_or_equal(index, Builtins.size(host))
        Ops.set(host, index, { "KEY" => keyword, "VALUE" => value })
      else
        Ops.set(host, [index, "VALUE"], value)
      end

      deep_copy(host)
    end

    # Validate server name
    # @param key any
    # @param id any
    # @param event map
    # @return [Boolean] valid servername
    def validate_servername(value)
      #    string value = Punycode::EncodeDomainName( (string)UI::QueryWidget (`id(key), `Value) );
      if !Hostname.CheckFQ(value)
        #translators: popup error message when validate servername
        Popup.Error(
          Ops.add(_("Invalid server name.") + "\n\n", Hostname.ValidFQ)
        )
        return false
      else
        return true
      end
    end

    # Validate IP for host
    # @param [Object] id any
    # @param [Object] key any
    # @param [Hash] event map
    # @return [Boolean] is IP valid
    def validate_serverip(id, key, event)
      id = deep_copy(id)
      key = deep_copy(key)
      event = deep_copy(event)
      Yast.import "IP"
      value = Convert.to_string(UI.QueryWidget(Id(id), :Value))

      # check, if there is also a port, if yes, skip it
      #    integer pos = search (value, ":");
      #    if (pos != nil) value = substring (value, 0, pos);

      # validate wildcard
      return true if value == "*"
      # remove brackets before validation (because of IPv6 [::])
      if Builtins.substring(value, 0, 1) == "[" &&
          Builtins.substring(value, Ops.subtract(Builtins.size(value), 1), 1) == "]"
        value = Builtins.substring(
          value,
          1,
          Ops.subtract(Builtins.size(value), 2)
        )
      end

      if !IP.Check(value)
        #translators: popup error message when validate server ip
        Popup.Error(_("Invalid IP address."))
        return false
      else
        return true
      end
    end

    # Function for validate server entries
    # @param [String] hostid string
    # @param [Array<Hash{String => Object>}] server list < map<string,any> >
    # @return [Boolean] valid server
    def validate_server(hostid, server)
      server = deep_copy(server)
      #TODO: don't allow user to use this directive !!!
      #main server can't use SSL
      valid = true
      Builtins.foreach(server) do |value|
        if Ops.get_string(value, "KEY", "") == "SSL"
          #translators: popup error message when validate server
          Report.Error(
            _("The default host cannot be configured with SSL support.")
          )
          valid = false
          next false
        end
      end if hostid == "main"
      return false if !valid

      hosts = YaST::HTTPDData.GetHostsList

      servername = Convert.to_string(get_host_value("ServerName", server, nil))
      ip = Convert.to_string(get_host_value("HostIP", server, nil))
      namebased = Convert.to_string(
        get_host_value("VirtualByName", server, nil)
      ) == "1"
      documentroot = Convert.to_string(
        get_host_value("DocumentRoot", server, "")
      )

      # for apache2.2 ServerName is not forced (if not - hostname will be used)
      if Builtins.size(servername) == 0
        if hostid == "main"
          Report.Warning(
            _("When no Server name is defined, hostname will be used instead.")
          )
          return true
        else
          #translators: popup error message when validate server
          Report.Error(_("Server name cannot be empty."))
          return false
        end
      end

      return false if !FileUtils.CheckAndCreatePath(documentroot)
      res = true

      Builtins.foreach(hosts) do |host|
        # skip ourself also when this is main server
        next if host == hostid || hostid == "main"
        next if host == "main"
        # find out the server name
        value = Convert.to_string(
          get_host_value("ServerName", YaST::HTTPDData.GetHost(host), nil)
        )
        if value == servername
          # error message - the entered server name is already configured
          # in another virtual host
          Report.Error(
            _(
              "The server name entered is already configured on another virtual host."
            )
          )
          res = false
          raise Break
        end
        vhost = YaST::HTTPDData.GetVhostType(host)
        if !FileUtils.CheckAndCreatePath(documentroot)
          res = false
          raise Break
        end
        if Ops.get_string(vhost, "id", "") == ip
          # this is valid only if both of them are name-based, not ip-based (bnc#486476)
          if !(Ops.get_string(YaST::HTTPDData.GetVhostType(host), "type", "") == "name-based" && namebased)
            # error message - the entered ip address is already
            # configured for another virtual host
            error_msg = Builtins.sformat(
              "%1 : %2",
              _("The IP address is already configured on another virtual host"),
              host
            )
            Report.Error(error_msg)
            res = false
            raise Break
          end
        end
      end

      # validate server admin
      serveradmin = Convert.to_string(
        get_host_value("ServerAdmin", server, nil)
      )
      if !Builtins.regexpmatch(serveradmin, ".+@.+")
        #translators: popup error message when validate ServerAdmin
        Report.Error(_("Administrator E-Mail is invalid."))
        res = false
      end

      res
    end




    #********************************** inital overview table *******************************

    # Reload server
    def ReloadServer
      SCR.Execute(path(".target.bash"), "rcapache2 reload")

      nil
    end
    # Handle function of the access log button (the first defined access log file)
    # @param [Object] key any key of the widget
    # @param [Hash] event map event that occured
    # @return value for wizard sequencer, always nil
    def showAccessLogPopup(key, event)
      key = deep_copy(key)
      event = deep_copy(event)
      # FIXME: log files needs to be done via HTTPDData
      # string log = (string) select( YaST::HTTPDData::GetAccessLogFiles( [currenthost] ), 0, "/var/log/apache2/access_log" );

      # strip the log format, if present
      log = ""
      #	log = select( splitstring( log, " " ), 0, "/var/log/apache2/access_log" );
      log = Ops.get(
        Builtins.splitstring(log, " "),
        0,
        "/var/log/apache2/access_log"
      )

      LogView.Display(
        {
          "command" => Builtins.sformat(
            "tail -f %1 -n 100 | /usr/sbin/logresolve2",
            log
          ),
          "save"    => true,
          "actions" => [
            # menubutton entry, try to keep short
            [
              _("&Reload HTTP Server"),
              fun_ref(method(:ReloadServer), "void ()")
            ],
            # menubutton entry, try to keep short
            [
              _("Save Settings and Re&start HTTP Server"),
              fun_ref(HttpServer.method(:Write), "boolean ()"),
              true
            ]
          ]
        }
      )
      nil
    end

    # Handle function of the error log button
    # @param [Object] key any key of the widget
    # @param [Hash] event map event that occured
    # @return value for wizard sequencer, always nil
    def showErrorLogPopup(key, event)
      key = deep_copy(key)
      event = deep_copy(event)
      # FIXME: log files needs to be done via HTTPDData
      # string log = (string) select( YaST::HTTPDData::GetErrorLogFiles( [currenthost] ), 0, "/var/log/apache2/error_log" );

      # strip the log format, if present
      log = ""
      #	log = select( splitstring( log, " " ), 0, "/var/log/apache2/error_log" );
      log = Ops.get(
        Builtins.splitstring(log, " "),
        0,
        "/var/log/apache2/error_log"
      )

      LogView.Display(
        {
          "command" => Builtins.sformat(
            "tail -f %1 -n 100 | /usr/sbin/logresolve2",
            log
          ),
          "save"    => true,
          "actions" => [
            # menubutton entry, try to keep short
            [
              _("&Reload HTTP Server"),
              fun_ref(method(:ReloadServer), "void ()")
            ],
            # menubutton entry, try to keep short
            [
              _("Save Settings and Re&start HTTP Server"),
              fun_ref(HttpServer.method(:Write), "boolean ()"),
              true
            ]
          ]
        }
      )
      nil
    end

    # Handle overview (listen) widget
    # @param [String] table string
    # @param [Hash] event map
    # @return [Symbol] (access/error popup)
    def OverviewHandle(table, event)
      event = deep_copy(event)
      # handle menu button entries
      if Ops.get(event, "ID") == :show_access_log
        return showAccessLogPopup(table, event)
      elsif Ops.get(event, "ID") == :show_error_log
        return showErrorLogPopup(table, event)
      end
      nil
    end


    #
    # @param [String] servername string
    # @param [String] ip string
    # @return [Hash{String => String}] servername:ip
    def AskNewInfo(servername, ip)
      if Builtins.size(servername) == 0
        # suggest reasonable value
        servername = Hostname.MergeFQ(DNS.hostname, DNS.domain) 
        # maybe we should check, if there is such host already
      end

      ips = Builtins.maplist(HttpServer.ip2device) { |ip2, dev| ip2 }
      UI.OpenDialog(
        VBox(
          # translators: popup description on changing the default host
          # the old default host is changed to a virtual one, but it may
          # miss some needed information. the popup asks to set them.
          Label(
            _(
              "The current default host will be replaced by \n" +
                "the new host and will become a virtual host.\n" +
                "\n" +
                "However, the current default host does not have\n" +
                "the IP address or the server name specified.\n" +
                "Therefore, it is not possible to use it as \n" +
                "a virtual host. Verify the suggested values below \n" +
                "and click OK to continue with the default host\n" +
                "switch. Otherwise click Cancel not to change\n" +
                "the default host.\n"
            )
          ),
          # translators: textentry to set the host name
          TextEntry(Id(:servername), _("Server &Name:"), servername),
          # translators: textentry to set the host IP address
          Left(
            ComboBox(Id("ip"), Opt(:editable), _("Server &IP Address:"), ips)
          ),
          VSpacing(0.5),
          HBox(
            PushButton(Id(:ok), Opt(:default), Label.ContinueButton),
            PushButton(Id(:cancel), Label.CancelButton)
          )
        )
      )
      UI.SetFocus(:servername)
      UI.ChangeWidget(Id("ip"), :Value, ip)

      ret = nil
      begin
        ret = Convert.to_symbol(UI.UserInput)
        break if ret == :cancel

        servername = Punycode.EncodeDomainName(
          Convert.to_string(UI.QueryWidget(:servername, :Value))
        )
        # it must be `ok
        next if !validate_servername(servername)


        next if !validate_serverip("ip", nil, nil)
        ip = Convert.to_string(UI.QueryWidget(Id("ip"), :Value))

        break
      end while ret != nil

      UI.CloseDialog
      ret != :cancel ? { "name" => servername, "ip" => ip } : nil
    end


    # Hosts contents
    # @param [Hash] descr map
    # @return [Array] host list
    def HostsContents(descr)
      descr = deep_copy(descr)
      Builtins.filter(YaST::HTTPDData.GetHostsList) { |row| row != "main" }
    end

    def changeButtons(stat)
      UI.ChangeWidget(:set_default, :Enabled, stat)
      UI.ChangeWidget(:_tp_delete, :Enabled, stat)
      UI.ChangeWidget(:_tp_edit, :Enabled, stat)

      nil
    end

    # Widget for delete host
    # @param [Object] opt_id any
    # @param [String] opt_key string
    # @return [Boolean] delete success
    def HostsDelete(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      if opt_id == "default"
        # translators: popup error message - default host cannot be deleted
        Popup.Error(_("Cannot delete the default host."))
        return false
      end
      # message popup
      return false if !Popup.YesNo(_("Delete selected host?"))

      HttpServer.modified = true
      ret = YaST::HTTPDData.DeleteHost(Convert.to_string(opt_id))
      if Builtins.size(HostsContents({})) == 0
        changeButtons(false)
      else
        changeButtons(true)
      end
      ret
    end

    # Get server name for host
    # @param [Object] key any
    # @param [String] id string
    # @return [String] server name
    def HostName(key, id)
      key = deep_copy(key)
      res = Convert.to_string(
        get_host_value(
          "ServerName",
          YaST::HTTPDData.GetHost(Convert.to_string(key)),
          Convert.to_string(key)
        )
      )
      res = Punycode.DecodeDomainName(res)
      # translators: human-readable "default host"
      res = _("Default Host") if key == "default" && res == "default"
      res
    end

    # Get document root for host
    # @param [Object] key any
    # @param [String] id string
    # @return [String] document root
    def HostDocumentRootSummary(key, id)
      key = deep_copy(key)
      Convert.to_string(
        get_host_value(
          "DocumentRoot",
          YaST::HTTPDData.GetHost(Convert.to_string(key)),
          ""
        )
      )
    end

    # Is that host default?
    # @param [Object] widget any
    # @param [String] key string
    # @return [Boolean] is_default?
    def HostIsDefault(widget, key)
      widget = deep_copy(widget)
      key == "default"
    end

    # Handle host widget
    # @param [String] table string
    # @param [Hash] event map
    # @return [Symbol] (`add, `edit)
    def HostsHandle(table, event)
      event = deep_copy(event)
      if Builtins.size(Convert.to_list(UI.QueryWidget(:_tp_table, :Items))) == 0
        changeButtons(false)
      else
        changeButtons(true)
      end

      if Ops.get(event, "ID") == :_tp_add
        return :add
      elsif Ops.get(event, "ID") == :_tp_edit
        @currenthost = Convert.to_string(
          UI.QueryWidget(:_tp_table, :CurrentItem)
        )
        return :edit
      elsif Ops.get(event, "ID") == :set_default
        host = Convert.to_string(UI.QueryWidget(:_tp_table, :CurrentItem))
        if host == "default"
          # popup - it is already the default host
          Popup.Message(_("The host is already default."))
          return nil
        end

        Builtins.y2milestone("Changing default host to '%1'", host)

        defhost_options = YaST::HTTPDData.GetHost("main")
        servername = Convert.to_string(
          get_host_value("ServerName", defhost_options, "")
        )
        ip = Convert.to_string(get_host_value("HostIP", defhost_options, ""))
        if ip == "" || servername != ""
          # we must set a new server name and ip for the old default host
          res = AskNewInfo(servername, ip)
          if res == nil
            # cancel the change
            return nil
          end

          ip = Ops.get_string(res, "ip", ip)
          servername = Ops.get_string(res, "name", ip)
          defhost_options = set_host_value("HostIP", defhost_options, ip)
          defhost_options = set_host_value(
            "ServerName",
            defhost_options,
            servername
          )
        end
        # move the old default host elsewhere
        YaST::HTTPDData.CreateHost(
          Ops.add(Ops.add(ip, "/"), servername),
          defhost_options
        )
        # replace the values of the default host by the new one
        YaST::HTTPDData.ModifyHost("main", YaST::HTTPDData.GetHost(host))
        # remove the old non-default host
        YaST::HTTPDData.DeleteHost(host)

        HttpServer.modified = true

        TablePopup.TableInit(@hosts_widget, table)
      else
        return TablePopup.TableHandle(@hosts_widget, table, event)
      end
      nil
    end

    # Initialize hosts table widget
    # @param [String] widget string
    def HostsInit(widget)
      @init_tab = "hosts"
      TablePopup.TableInit(@hosts_widget, widget)
      @vhost_descr = []
      # menu button label
      UI.ReplaceWidget(
        Id(:_tp_table_repl),
        PushButton(Id(:set_default), _("Set as De&fault"))
      )

      nil
    end

    # Initialize host widget
    # @param [String] key string
    def HostInit(key)
      if key == "MAIN_HOST"
        @init_tab = "main_host"
        @currenthost = "main"
      end
      TablePopup.TableInit(@hostwidget, key)

      nil
    end

    # Get host options
    # @return [Hash] host options
    def getHostOptions(mainhost)
      used = {}
      directives = []
      Builtins.foreach(YaST::HTTPDData.GetKnownModules) do |mod|
        Builtins.foreach(Ops.get_list(mod, "directives", [])) do |option|
          opt_list = []
          Builtins.foreach(Ops.get_list(option, "values", [])) do |value|
            opt_list = Builtins.add(opt_list, [value])
          end
          if Builtins.contains(Ops.get_list(option, "context", []), "Server") &&
              !Builtins.contains(Ops.get_list(option, "context", []), "SSL")
            if opt_list != []
              Ops.set(
                used,
                Ops.get_string(option, "option", ""),
                { "popup" => { "widget" => :combobox, "items" => opt_list } }
              )
            else
              Ops.set(used, Ops.get_string(option, "option", ""), {})
            end
          end
        end
      end
      if mainhost
        used = Builtins.union(used, Builtins.filter(@popups) do |key, val|
          key != "SSL"
        end)
      else
        used = Builtins.union(used, @popups)
      end
      deep_copy(used)
    end
    def getSSLOptions
      used = {}
      directives = []
      Builtins.foreach(YaST::HTTPDData.GetKnownModules) do |mod|
        Builtins.foreach(Ops.get_list(mod, "directives", [])) do |option|
          opt_list = []
          Builtins.foreach(Ops.get_list(option, "values", [])) do |value|
            opt_list = Builtins.add(opt_list, [value])
          end
          if Builtins.contains(Ops.get_list(option, "context", []), "SSL")
            if opt_list != []
              Ops.set(
                used,
                Ops.get_string(option, "option", ""),
                { "popup" => { "widget" => :combobox, "items" => opt_list } }
              )
            else
              Ops.set(used, Ops.get_string(option, "option", ""), {})
            end
          end
        end
      end
      deep_copy(used)
    end

    # Initialize directory table
    # @param [String] widget string
    def DirInit(widget)
      TablePopup.TableInit(@dirwidget, widget)
      UI.ChangeWidget(:dir_name, :Value, @dir_value)

      nil
    end

    # Get directory options
    # @return [Hash] directory options
    def getDirOptions
      used = {}
      directives = []
      Builtins.foreach(YaST::HTTPDData.GetKnownModules) do |mod|
        Builtins.foreach(Ops.get_list(mod, "directives", [])) do |option|
          opt_list = []
          Builtins.foreach(Ops.get_list(option, "values", [])) do |value|
            opt_list = Builtins.add(opt_list, [value])
          end
          if Builtins.contains(Ops.get_list(option, "context", []), "Directory") &&
              !Builtins.contains(Ops.get_list(option, "context", []), "SSL")
            if opt_list != []
              Ops.set(
                used,
                Ops.get_string(option, "option", ""),
                { "popup" => { "widget" => :combobox, "items" => opt_list } }
              )
            else
              Ops.set(used, Ops.get_string(option, "option", ""), {})
            end
          end
        end
      end
      deep_copy(used)
    end

    # Handle directory table
    # @param [String] key string
    # @param [Hash] event map
    # @return [Symbol] tablehandle
    def handleDirTable(key, event)
      event = deep_copy(event)
      @host_options = nil if Ops.get(event, "ID") == :back

      TablePopup.TableHandle(@dirwidget, key, event)
    end

    # Initialize directory popup
    # @param [Object] option_id any
    # @param [String] option_type string
    def DirPopupInit(option_id, option_type)
      option_id = deep_copy(option_id)
      value = Ops.get_string(
        @host_options,
        [Convert.to_integer(option_id), "VALUE"],
        ""
      )

      nil
    end


    # Store directory map
    # @param [String] key string
    # @param [Hash] event map
    def DirStore(key, event)
      event = deep_copy(event)
      options = []
      new_dir = Convert.to_string(UI.QueryWidget(:dir_name, :Value))
      dir_before = false
      host = YaST::HTTPDData.GetHost(@currenthost)
      Builtins.foreach(host) do |option|
        if Ops.get_string(option, "KEY", "unknown") == "_SECTION" &&
            Ops.get_string(option, "SECTIONNAME", "unknown") == "Directory" &&
            Ops.get_string(option, "SECTIONPARAM", "unknown") == @dir_value
          dir_before = true
          newlist = []
          Builtins.foreach(@host_options) do |key2, value|
            newlist = Builtins.add(newlist, value)
          end
          Ops.set(option, "VALUE", newlist)
          Ops.set(option, "SECTIONPARAM", new_dir)
        end
        options = Builtins.add(options, option)
      end
      if !dir_before
        newlist = []
        Builtins.foreach(@host_options) do |key2, value|
          newlist = Builtins.add(newlist, value)
        end
        #		options = add(options, $["VALUE":newlist]);
        options = Builtins.add(
          host,
          {
            "KEY"          => "_SECTION",
            "SECTIONNAME"  => "Directory",
            "SECTIONPARAM" => new_dir,
            "VALUE"        => newlist
          }
        )
      end
      YaST::HTTPDData.ModifyHost(@currenthost, options)
      setHostOptions(nil)
      HttpServer.modified = true

      nil
    end

    def initVhostRes(key)
      vhost = YaST::HTTPDData.GetVhostType(@currenthost)
      if @vhost_descr != []
        vhost = {}
        Builtins.foreach(@vhost_descr) do |row|
          if Ops.get_string(row, "KEY", "") == "HostIP"
            Ops.set(vhost, "id", Ops.get_string(row, "VALUE", ""))
          end
          if Ops.get_string(row, "KEY", "") == "VirtualByName"
            Ops.set(
              vhost,
              "type",
              Ops.get_string(row, "VALUE", "0") == "0" ? "ip-based" : "name-based"
            )
          end
        end
      end

      if Ops.get_string(vhost, "type", "") == "ip-based"
        UI.ChangeWidget(:resolution, :CurrentButton, :ip_based)
      else
        UI.ChangeWidget(:resolution, :CurrentButton, :name_based)
      end
      UI.ChangeWidget(:virtual_host, :Value, Ops.get_string(vhost, "id", ""))
      UI.ChangeWidget(:virtual_host, :Enabled, false)

      nil
    end

    def initVhostId(key)
      if @vhost_descr != []
        servername = ""
        Builtins.foreach(@vhost_descr) do |row|
          if Ops.get_string(row, "KEY", "") == "ServerName"
            servername = Ops.get_string(row, "VALUE", "")
          end
        end
        documentroot = ""
        Builtins.foreach(@vhost_descr) do |row|
          if Ops.get_string(row, "KEY", "") == "DocumentRoot"
            documentroot = Ops.get_string(row, "VALUE", "")
          end
        end
        admin = ""
        Builtins.foreach(@vhost_descr) do |row|
          if Ops.get_string(row, "KEY", "") == "ServerAdmin"
            admin = Ops.get_string(row, "VALUE", "")
          end
        end
        if Ops.greater_than(Builtins.size(servername), 0)
          UI.ChangeWidget(
            :servername,
            :Value,
            Punycode.DecodeDomainName(servername)
          )
        end
        if Ops.greater_than(Builtins.size(documentroot), 0)
          UI.ChangeWidget(:documentroot, :Value, documentroot)
        end
        if Ops.greater_than(Builtins.size(admin), 0)
          UI.ChangeWidget(:admin, :Value, admin)
        end
      end

      UI.SetFocus(:servername)

      nil
    end

    def handleVhostId(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventType", "") == "WidgetEvent" &&
          Ops.get(event, "WidgetID") == :browse
        dir = UI.AskForExistingDirectory("/srv", _("Choose Document Root"))
        UI.ChangeWidget(:documentroot, :Value, dir) if dir != nil
      end
      nil
    end

    def validateVhostId(key, event)
      event = deep_copy(event)
      # FIXME: Do checks about the IP address availability
      ip = Convert.to_string(UI.QueryWidget(:virtual_host, :Value))
      servername = Punycode.EncodeDomainName(
        Convert.to_string(UI.QueryWidget(:servername, :Value))
      )
      documentroot = Convert.to_string(UI.QueryWidget(:documentroot, :Value))
      admin = Convert.to_string(UI.QueryWidget(:admin, :Value))
      virtualbyname = Convert.to_boolean(UI.QueryWidget(:name_based, :Value))

      return false if !validate_servername(servername)

      #     if (! validate_serverip("", "ipaddress", nil)) return false;

      if Builtins.size(admin) == 0
        # translators: error popup
        Popup.Error(_("Administrator E-Mail cannot be empty."))
        return nil
      end

      @vhost_descr = [
        { "KEY" => "DocumentRoot", "VALUE" => documentroot },
        { "KEY" => "ServerName", "VALUE" => servername },
        { "KEY" => "ServerAdmin", "VALUE" => admin },
        { "KEY" => "VirtualByName", "VALUE" => virtualbyname ? "1" : "0" },
        { "KEY" => "HostIP", "VALUE" => ip },
        {
          "KEY"          => "_SECTION",
          "SECTIONNAME"  => "Directory",
          "SECTIONPARAM" => documentroot,
          "VALUE"        => [
            { "KEY" => "AllowOverride", "VALUE" => "None" },
            { "KEY" => "Require", "VALUE" => "all granted" }
          ],
          "OVERHEAD"     => ""
        }
      ]
      return false if !validate_server(nil, @vhost_descr)
      true
    end

    def storeVhostId(opt_id, event)
      event = deep_copy(event)
      nil
    end

    def changeVHostPopup(value)
      vhost = ""
      items = Builtins.maplist(HttpServer.ip2device) do |ip, dev|
        if IP.Check6(ip)
          next Builtins.sformat("[%1]", ip)
        else
          next ip
        end
      end
      UI.OpenDialog(
        RadioButtonGroup(
          Id(:rb),
          VBox(
            Left(
              RadioButton(
                Id(:all_addr),
                Opt(:notify),
                _("All addresses (*)"),
                true
              )
            ),
            Left(RadioButton(Id(:multiselect), Opt(:notify), "")),
            MultiSelectionBox(Id(:ipaddress), _("IP Addresses"), items),
            Left(RadioButton(Id(:custom), Opt(:notify), "")),
            TextEntry(Id(:serv_name), _("ServerName")),
            VSpacing(),
            ButtonBox(
              PushButton(Id(:ok), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            )
          )
        )
      )
      if value == "*" || value == ""
        UI.ChangeWidget(:serv_name, :Value, value)
      else
        it = []
        Builtins.foreach(
          Convert.convert(items, :from => "list", :to => "list <string>")
        ) do |ip|
          it = Builtins.add(
            it,
            Item(
              Id(ip),
              ip,
              Builtins.contains(Builtins.splitstring(value, " "), ip)
            )
          )
        end
        unknown = false
        Builtins.foreach(Builtins.splitstring(value, " ")) do |ip|
          unknown = true if !Builtins.contains(items, ip)
        end
        if unknown
          UI.ChangeWidget(:serv_name, :Value, value)
          UI.ChangeWidget(:rb, :CurrentButton, :custom)
        else
          UI.ChangeWidget(:ipaddress, :Items, it)
          UI.ChangeWidget(:rb, :CurrentButton, :multiselect)
        end
      end

      ret = nil
      begin
        rb = Convert.to_symbol(UI.QueryWidget(Id(:rb), :CurrentButton))
        UI.ChangeWidget(Id(:ipaddress), :Enabled, rb == :multiselect)
        UI.ChangeWidget(Id(:serv_name), :Enabled, rb == :custom)
        ret = Convert.to_symbol(UI.UserInput)
      end while ret != :ok && ret != :cancel
      if ret == :ok
        case Convert.to_symbol(UI.QueryWidget(Id(:rb), :CurrentButton))
          when :all_addr
            vhost = "*"
          when :multiselect
            @selected = Convert.convert(
              UI.QueryWidget(Id(:ipaddress), :SelectedItems),
              :from => "any",
              :to   => "list <string>"
            )
            vhost = Builtins.mergestring(@selected, " ")
          when :custom
            vhost = Convert.to_string(UI.QueryWidget(Id(:serv_name), :Value))
          else
            vhost = ""
            Builtins.y2warning("unrecognized selection")
        end
      end
      UI.CloseDialog
      vhost
    end


    def handleVhostRest(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventReason", "") == "Activated" &&
          Ops.get(event, "ID") == :change_vhost
        vhost = changeVHostPopup(
          Convert.to_string(UI.QueryWidget(:virtual_host, :Value))
        )
        if Ops.greater_than(Builtins.size(vhost), 0)
          UI.ChangeWidget(Id(:virtual_host), :Value, vhost)
        end
      end
      nil
    end


    def validateVhostRes(key, event)
      event = deep_copy(event)
      vhost = Convert.to_string(UI.QueryWidget(Id(:virtual_host), :Value))
      if Builtins.size(vhost) == 0
        Popup.Error(_("Name for VirtualHost ID cannot be empty."))
        return false
      end

      # for name-based vhost only IP address is allowed
      # or regexp (* or *:port) or list of IP addresses
      if UI.QueryWidget(:resolution, :Value) == :name_based
        # regexp matches '*' and '*:80'
        return true if Builtins.regexpmatch(vhost, "^\\*$|^\\*:[[:digit:]]+$")
        ok = true
        Builtins.foreach(Builtins.splitstring(vhost, " ")) do |ip|
          ok = false if !IP.Check4(ip)
        end
        if !ok
          Popup.Warning(
            _(
              "To use name-based virtual hosting,\n" +
                "you must designate the IP address on the server\n" +
                "that will be accepting requests for the hosts.\n" +
                "Also * for all addresses and *:port are acceptable."
            )
          )
        end
        return ok
      end
      true
    end
    def initVhostDetails(key)
      servername = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "ServerName"
      end
      ip = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "HostIP"
      end

      @dns_zone = ""

      if HttpServer.configured_dns
        if IP.Check4(Ops.get_string(ip, "VALUE", ""))
          Builtins.foreach(DnsServerAPI.GetZones) do |key2, value|
            if Ops.get_string(value, "type", "") == "master"
              if Builtins.regexpmatch(
                  Ops.get_string(servername, "VALUE", ""),
                  Ops.add(Ops.add("\\.", key2), "$")
                ) &&
                  Ops.greater_than(
                    Builtins.size(key2),
                    Builtins.size(@dns_zone)
                  )
                @dns_zone = key2
              end
              Builtins.y2milestone(_("Master Zone %1"), key2)
            else
              Builtins.y2warning("Zone %1 is not type master", key2)
            end
          end
          if Ops.greater_than(Builtins.size(@dns_zone), 0)
            Builtins.y2milestone("Matching zone %1", @dns_zone)
            exists = false
            Builtins.foreach(DnsServerAPI.GetZoneRRs(@dns_zone)) do |records|
              if Ops.get_string(records, "key", "") ==
                  Ops.get_string(servername, "VALUE", "") ||
                  Ops.get_string(records, "key", "") ==
                    Ops.add(Ops.get_string(servername, "VALUE", ""), ".")
                exists = true
              end
            end
            if exists == true
              Builtins.y2milestone(
                _("Record %1 already exists in zone %2."),
                Ops.get_string(servername, "VALUE", ""),
                @dns_zone
              )
            else
              UI.ReplaceWidget(
                :replace,
                Frame(
                  _("DNS Settings"),
                  Left(
                    HBox(
                      Label(Ops.get_string(servername, "VALUE", "")),
                      PushButton(Id(:dns_add_rec), _("Add to Zone"))
                    )
                  )
                )
              )
            end
          else
            opts = Builtins.splitstring(
              Ops.get_string(servername, "VALUE", ""),
              "."
            )
            Ops.set(opts, 0, nil)
            newList = []
            Builtins.foreach(opts) do |it|
              if it != nil
                tmpList = []
                Builtins.foreach(newList) do |itzone|
                  if !Builtins.contains(
                      Map.Keys(DnsServerAPI.GetZones),
                      Ops.add(Ops.add(itzone, "."), it)
                    )
                    tmpList = Builtins.add(
                      tmpList,
                      Ops.add(Ops.add(itzone, "."), it)
                    )
                  else
                    Builtins.y2warning(
                      "%1 is already configured zone",
                      Ops.add(Ops.add(itzone, "."), it)
                    )
                  end
                end
                newList = deep_copy(tmpList)
                newList = Builtins.add(newList, it)
              end
            end

            if Ops.greater_than(Builtins.size(opts), 0)
              UI.ReplaceWidget(
                :replace,
                Frame(
                  _("DNS Settings"),
                  Left(
                    HBox(
                      Label(Ops.get_string(servername, "VALUE", "")),
                      ComboBox(Id(:new_zone), _("Zone Name"), newList),
                      PushButton(Id(:dns_create_zone), _("Create New Zone"))
                    )
                  )
                )
              )
            end
          end
        else
          Builtins.y2warning(
            "%1 is not valid IP4 address",
            Ops.get_string(ip, "VALUE", "")
          )
        end
      end

      # disable using SSL for name-based virtual host
      Builtins.foreach(@vhost_descr) do |row|
        if Ops.get_string(row, "KEY", "") == "VirtualByName" &&
            Ops.get_string(row, "VALUE", "0") == "1"
          UI.ChangeWidget(:ssl_support, :Enabled, false)
        end
      end

      nil
    end

    def handleVhostDetails(key, event)
      event = deep_copy(event)
      documentroot = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "DocumentRoot"
      end
      ip = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "HostIP"
      end
      servername = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "ServerName"
      end

      if Convert.to_boolean(UI.QueryWidget(:cgi_support, :Value))
        UI.ChangeWidget(:cgi_dir, :Enabled, true)
        UI.ChangeWidget(:browse_cgi_dir, :Enabled, true)
      else
        UI.ChangeWidget(:cgi_dir, :Enabled, false)
        UI.ChangeWidget(:browse_cgi_dir, :Enabled, false)
      end
      if Convert.to_boolean(UI.QueryWidget(:ssl_support, :Value))
        UI.ChangeWidget(:certfile, :Enabled, true)
        UI.ChangeWidget(:browse_cert, :Enabled, true)
        UI.ChangeWidget(:keyfile, :Enabled, true)
        UI.ChangeWidget(:browse_key, :Enabled, true)
      else
        UI.ChangeWidget(:certfile, :Enabled, false)
        UI.ChangeWidget(:browse_cert, :Enabled, false)
        UI.ChangeWidget(:keyfile, :Enabled, false)
        UI.ChangeWidget(:browse_key, :Enabled, false)
      end


      if Ops.get(event, "WidgetClass") == :PushButton
        case Ops.get_symbol(event, "ID")
          when :dns_add_rec
            Builtins.y2milestone(
              "Add record %1 to zone %2",
              Ops.get_string(servername, "VALUE", ""),
              @dns_zone
            )
            UI.ChangeWidget(:dns_add_rec, :Enabled, false)
            DnsServerAPI.AddZoneRR(
              @dns_zone,
              "A",
              Ops.add(Ops.get_string(servername, "VALUE", ""), "."),
              Ops.get_string(ip, "VALUE", "")
            )
          when :dns_create_zone
            Builtins.y2milestone(
              "Create new zone ... %1",
              UI.QueryWidget(:new_zone, :Value)
            )
            UI.ChangeWidget(:dns_create_zone, :Enabled, false)
            UI.ChangeWidget(:new_zone, :Enabled, false)
            @dns_zone = Convert.to_string(UI.QueryWidget(:new_zone, :Value))
            DnsServerAPI.AddZone(@dns_zone, "master", {})
            DnsServerAPI.AddZoneRR(
              @dns_zone,
              "A",
              Ops.add(Ops.get_string(servername, "VALUE", ""), "."),
              Ops.get_string(ip, "VALUE", "")
            )
          when :browse_cgi_dir
            cgi_dir = UI.AskForExistingDirectory(
              "/srv/www/cgi-bin",
              _("CGI Directory")
            )
            UI.ChangeWidget(:cgi_dir, :Value, cgi_dir) if cgi_dir != nil
          when :browse_cert
            cert_file = UI.AskForExistingFile(
              "/etc/apache2/ssl.crt",
              "*.crt *.pem",
              _("Choose Certificate File")
            )
            if cert_file != nil &&
                SCR.Execute(
                  path(".target.bash"),
                  Builtins.sformat("openssl x509 -in %1", cert_file)
                ) == 0
              UI.ChangeWidget(:certfile, :Value, cert_file)
            else
              UI.ChangeWidget(:certfile, :Value, "")
              # translators: error popup
              Popup.Error(_("Enter the certificate file."))
            end
          when :browse_key
            key_file = UI.AskForExistingFile(
              "/etc/apache2/ssl.key",
              "*.key *.pem",
              _("Choose Certificate Key File")
            )
            #   boolean keyfile = (SCR::Execute(.target.bash, sformat("openssl rsa -in %1", cert_file))==0)?true:false;
            if key_file != nil &&
                SCR.Execute(
                  path(".target.bash"),
                  Builtins.sformat("openssl rsa -in %1", key_file)
                ) == 0
              UI.ChangeWidget(:keyfile, :Value, key_file)
            else
              UI.ChangeWidget(:keyfile, :Value, "")
              # translators: error popup
              Popup.Error(_("Enter the key file."))
            end
        end
      end

      nil
    end

    def storeVhostDetails(key, events)
      events = deep_copy(events)
      ip = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "HostIP"
      end
      servername = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "ServerName"
      end
      documentroot = Builtins.find(@vhost_descr) do |row|
        Ops.get_string(row, "KEY", "") == "DocumentRoot"
      end

      if UI.QueryWidget(:cgi_support, :Value) == true
        _alias = Ops.add(
          "/cgi-bin/ ",
          Convert.to_string(UI.QueryWidget(:cgi_dir, :Value))
        )
        @vhost_descr = Builtins.add(
          @vhost_descr,
          { "KEY" => "ScriptAlias", "VALUE" => _alias }
        )
        @vhost_descr = Builtins.add(
          @vhost_descr,
          {
            "KEY"          => "_SECTION",
            "SECTIONNAME"  => "Directory",
            "SECTIONPARAM" => UI.QueryWidget(:cgi_dir, :Value),
            "VALUE"        => [
              { "KEY" => "AllowOverride", "VALUE" => "None" },
              { "KEY" => "Options", "VALUE" => "+ExecCGI -Includes" },
              { "KEY" => "Require", "VALUE" => "all granted" }
            ],
            "OVERHEAD"     => ""
          }
        )
        Builtins.y2milestone("CGI support for virtual host added")
      end

      ssl_values = {}
      if UI.QueryWidget(:ssl_support, :Value) == true
        cert_file = Builtins.tostring(UI.QueryWidget(:certfile, :Value))
        key_file = Builtins.tostring(UI.QueryWidget(:keyfile, :Value))

        if Ops.greater_than(Builtins.size(cert_file), 0) &&
            Ops.greater_than(Builtins.size(key_file), 0)
          YaST::HTTPDData.ModifyModuleList(["ssl"], true)
          YaST::HTTPDData.ModifyModuleList(["socache_shmcb"], true)
          ssl_values = {
            "KEY"          => "_SECTION",
            "SECTIONNAME"  => "IfDefine",
            "SECTIONPARAM" => "SSL",
            "VALUE"        => [
              { "KEY" => "SSLCertificateFile", "VALUE" => cert_file },
              { "KEY" => "SSLCertificateKeyFile", "VALUE" => key_file },
              { "KEY" => "SSLEngine", "VALUE" => "on" }
            ]
          }
        else
          Builtins.y2error("%1 is not valid Certificate File!", cert_file)
        end
      end

      if Ops.greater_than(Builtins.size(ssl_values), 0)
        @vhost_descr = Builtins.add(@vhost_descr, ssl_values)
      end


      #		  vhost_descr = YaST::HTTPDData::GetHost(ip["VALUE"]:""+"/"+servername["VALUE"]:"");
      directory_index = Convert.to_string(UI.QueryWidget(:dir_index, :Value))

      if Ops.greater_than(Builtins.size(directory_index), 0)
        tmp_descr = []

        Builtins.foreach(@vhost_descr) do |value|
          if Ops.get_string(value, "KEY", "") == "_SECTION" &&
              Ops.get_string(value, "SECTIONNAME", "") == "Directory" &&
              Builtins.search(
                Ops.get_string(value, "SECTIONPARAM", ""),
                Ops.get_string(documentroot, "VALUE", "")
              ) != nil
            #				  if (size(directory_index)>0)
            Ops.set(
              value,
              "VALUE",
              Builtins.add(
                Ops.get_list(value, "VALUE", []),
                { "KEY" => "DirectoryIndex", "VALUE" => directory_index }
              )
            )
          end
          tmp_descr = Builtins.add(tmp_descr, value) #			vhost_descr = add(vhost_descr, value);
        end
        @vhost_descr = deep_copy(tmp_descr)
      end
      #		 }
      if UI.QueryWidget(:pub_html, :Value) == true
        @vhost_descr = Builtins.add(
          @vhost_descr,
          { "KEY" => "UserDir", "VALUE" => "public_html" }
        )
      end
      if YaST::HTTPDData.CreateHost(
          Ops.add(
            Ops.add(Ops.get_string(ip, "VALUE", ""), "/"),
            Ops.get_string(servername, "VALUE", "")
          ),
          @vhost_descr
        ) == nil
        error = YaST::HTTPDData.Error
        Popup.Error(Ops.get(error, "summary", ""))
      end
      HttpServer.modified = true
      @vhost_descr = []

      nil
    end


    #******************************* SSL widget ***************************

    # Handle SSL widget table
    # @param [String] key string
    # @param [Hash] event map
    # @return [Symbol] sslhandle
    def handleSSLTable(key, event)
      event = deep_copy(event)
      if Ops.get(event, "ID") == :import_certificate
        #translators: dialog to set *.pem file with certificate
        pem = UI.AskForExistingFile("/", "*.pem", _("Select Certificate"))
        if pem == nil
          # cancel
          return nil
        end

        cert = Convert.to_string(SCR.Read(path(".target.string"), pem))
        if cert != nil
          # pass the data to the backend
          YaST::HTTPDData.SetCert(@currenthost, "CERT", cert)

          # get the correct host name
          host = YaST::HTTPDData.GetHost(@currenthost)
          host = set_host_value(
            "SSLCertificateFile",
            host,
            Ops.add(
              Ops.add(
                "/etc/apache2/ssl.crt/",
                Convert.to_string(get_host_value("ServerName", host, "default"))
              ),
              "-cert.pem"
            )
          )
          YaST::HTTPDData.ModifyHost(@currenthost, host)
          TablePopup.TableInitWrapper(key)
          return nil
        end

        # translators: error message un failed certificate import
        Report.Error(Builtins.sformat(_("Cannot import certificate\n%1"), pem))
      elsif Ops.get(event, "ID") == :common_certificate
        pem = "/etc/ssl/servercerts/servercert.pem"
        if !CheckCommonServerCertificate()
          #translators: dialog to set *.pem file with certificate
          pem = UI.AskForExistingFile(
            "/etc/ssl/servercerts",
            "*.pem",
            _("Select Certificate")
          )
          if pem == nil
            # cancelled
            return nil
          end
        else
          host = YaST::HTTPDData.GetHost(@currenthost)
          host = set_host_value(
            "SSLCertificateFile",
            host,
            "/etc/ssl/servercerts/servercert.pem"
          )
          host = set_host_value(
            "SSLCertificateKeyFile",
            host,
            "/etc/ssl/servercerts/serverkey.pem"
          )
          YaST::HTTPDData.ModifyHost(@currenthost, host)
        end

        TablePopup.TableInitWrapper(key)
        return nil
      elsif Ops.get(event, "ID") == :back
        @host_options = nil
      end

      TablePopup.TableHandle(@sslwidget, key, event)
    end

    # Initialize SSL widget
    # @param [String] widget string
    def SSLInit(widget)
      TablePopup.TableInit(@sslwidget, widget)

      nil
    end

    # Store SSL setting
    # @param [String] key string
    # @param [Hash] event map
    def SSLStore(key, event)
      event = deep_copy(event)
      found = false
      forssl = []
      fordir = []


      Builtins.foreach(@host_options) do |key2, value|
        Builtins.foreach(YaST::HTTPDData.GetKnownModules) do |val|
          if Ops.get_string(val, "name", "") == "ssl"
            Builtins.foreach(Ops.get_list(val, "directives", [])) do |pom|
              if Ops.get_string(pom, "option", "") ==
                  Ops.get_string(value, "KEY", "")
                if Builtins.contains(
                    Ops.get_list(pom, "context", []),
                    "Directory"
                  )
                  fordir = Builtins.add(fordir, value)
                end
                if Builtins.contains(Ops.get_list(pom, "context", []), "Server")
                  forssl = Builtins.add(forssl, value)
                end
              end
            end
          end
        end
      end


      options = []

      vhost = YaST::HTTPDData.GetVhostType(@currenthost)
      if Ops.get_string(vhost, "type", "") == "ip-based"
        options = Builtins.add(
          options,
          { "KEY" => "VirtualByName", "VALUE" => "0" }
        )
      else
        options = Builtins.add(
          options,
          { "KEY" => "VirtualByName", "VALUE" => "1" }
        )
      end
      options = Builtins.add(
        options,
        { "KEY" => "HostIP", "VALUE" => Ops.get_string(vhost, "id", "") }
      )

      Builtins.foreach(YaST::HTTPDData.GetHost(@currenthost)) do |option|
        if Ops.get_string(option, "KEY", "unknown") == "_SECTION" &&
            Ops.get_string(option, "SECTIONPARAM", "unknown") == "SSL"
          found = true
          Ops.set(option, "VALUE", forssl)
          if Ops.greater_than(Builtins.size(forssl), 0)
            options = Builtins.add(options, option)
          end
        elsif Ops.get_string(option, "KEY", "unknown") == "_SECTION" &&
            Ops.get_string(option, "SECTIONNAME", "unknown") == "Directory"
          temp_dir = []
          Builtins.foreach(Ops.get_list(option, "VALUE", [])) do |value|
            if !(Ops.get_string(value, "KEY", "unknown") == "_SECTION" &&
                Ops.get_string(value, "SECTIONPARAM", "unknown") == "SSL")
              temp_dir = Builtins.add(temp_dir, value)
            end
          end
          if fordir != []
            Ops.set(
              option,
              "VALUE",
              Builtins.add(
                temp_dir,
                {
                  "KEY"          => "_SECTION",
                  "SECTIONNAME"  => "IfDefine",
                  "SECTIONPARAM" => "SSL",
                  "VALUE"        => fordir
                }
              )
            )
          else
            dir_newlist = []
            Builtins.foreach(Ops.get_list(option, "VALUE", [])) do |dir_item|
              if !(Ops.get_string(dir_item, "KEY", "") == "_SECTION" &&
                  Ops.get_string(dir_item, "SECTIONPARAM", "") == "SSL")
                dir_newlist = Builtins.add(dir_newlist, dir_item)
              end
            end
            Ops.set(option, "VALUE", dir_newlist)
          end

          options = Builtins.add(options, option)
        else
          options = Builtins.add(options, option)
        end
      end
      if !found
        options = Builtins.add(
          options,
          {
            "KEY"          => "_SECTION",
            "SECTIONNAME"  => "IfDefine",
            "SECTIONPARAM" => "SSL",
            "VALUE"        => forssl
          }
        )
      end
      #TODO::SSLWrite()
      YaST::HTTPDData.ModifyHost(@currenthost, options)
      setHostOptions(nil)
      HttpServer.modified = true

      nil
    end

    #******************************* Listen popup ***************************

    # Convert a Listen string to an item for table. Splits by the colon.
    #
    # @param [Hash{String => Object}] arg		the Listen map
    # @param [Fixnum] id		the id of this item
    # @return [Yast::Term]		term for the table
    def listen2item(arg, id)
      arg = deep_copy(arg)
      #translators: all network addresses Listen type
      address = Ops.get_locale(arg, "ADDRESS", _("All Addresses"))
      #translators: all network addresses Listen type
      address = _("All Addresses") if address == ""
      port = Ops.get_string(arg, "PORT", "80")

      Item(Id(id), address, port)
    end

    # Show a popup for editing Listen statement.
    #
    # @param [String] network string initial value for the network part of the statement
    #                  If empty or _("All Addresses"), considered for all Listen for all interfaces.
    # @param [String] port string initial value for a port number
    # @return [Hash{String => String}]	the new Listen statement or nil if Cancel was pressed
    def AskListen(network, port)
      # translators: all network addresses Listen type
      adr_type = network == _("All Addresses") || network == ""
      port = "" if port == nil

      # translators: Listen type for all addresses;
      aa = _("All Addresses")

      ips = Builtins.union([aa], Builtins.maplist(HttpServer.ip2device) do |ip, dev|
        if IP.Check6(ip)
          next Builtins.sformat("[%1]", ip)
        else
          next ip
        end
      end)
      UI.OpenDialog(
        VBox(
          TextEntry(Id(:port), Label.Port, port),
          # translators: combo box label for list of configured IPs
          Left(
            ComboBox(Id("address"), Opt(:editable), _("Network &Address:"), ips)
          ),
          VSpacing(),
          ButtonBox(
            PushButton(Id(:ok), Label.OKButton),
            PushButton(Id(:cancel), Label.CancelButton)
          )
        )
      )

      UI.ChangeWidget(Id("address"), :Value, network) if !adr_type

      ret = nil
      res = {}
      begin
        ret = Convert.to_symbol(UI.UserInput)

        if ret == :ok
          Ops.set(
            res,
            "ADDRESS",
            Convert.to_string(UI.QueryWidget(Id("address"), :Value))
          )
          Ops.set(
            res,
            "PORT",
            Convert.to_string(UI.QueryWidget(Id(:port), :Value))
          )
          if Ops.get(res, "ADDRESS") == aa
            # on all addresses, cleanup the value
            Ops.set(res, "ADDRESS", "")
          else
            # validate
            if !validate_serverip("address", nil, nil)
              ret = nil
              next
            end
          end

          # validation
          if !Builtins.regexpmatch(
              Ops.get(res, "PORT", ""),
              "^[ \t]*[0-9]+[ \t]*$"
            )
            # translators: error message when validating Listen statement
            Popup.Error(_("Invalid port number."))
            ret = nil
            next
          end
        end
      end while ret != :ok && ret != :cancel

      res = nil if ret == :cancel

      UI.CloseDialog

      deep_copy(res)
    end

    # Validate server function
    # @param [String] id string
    # @param [Hash] key map
    # @return [Boolean] validate
    def validate_server_fnc(id, key)
      key = deep_copy(key)
      # convert the map to list
      val = Builtins.maplist(@host_options) { |index, data| data }
      if @currenthost != "main"
        val = Builtins.add(
          val,
          {
            "KEY"   => "HostIP",
            "VALUE" => Convert.to_string(
              UI.QueryWidget(Id(:virtual_host), :Value)
            )
          }
        )
        val = Builtins.add(
          val,
          {
            "KEY"   => "VirtualByName",
            "VALUE" => UI.QueryWidget(Id(:resolution), :Value) == :ip_based ? "0" : "1"
          }
        )
      end
      validate_server(@currenthost, val)
    end

    # Get value from id
    # @param [Hash] desc map
    # @param [Object] option_id any
    # @return [String] value
    def HostId2Key(desc, option_id)
      desc = deep_copy(desc)
      option_id = deep_copy(option_id)
      Ops.get_string(@host_options, [Convert.to_integer(option_id), "KEY"], "")
    end
    def checkLoadedModuleFor(new)
      loaded = YaST::HTTPDData.GetModuleList
      Builtins.foreach(YaST::HTTPDData.GetKnownModules) do |value|
        if Builtins.contains(Ops.get_list(value, "directives", []), new) &&
            !Builtins.contains(loaded, Ops.get_string(value, "name", ""))
          YaST::HTTPDData.ModifyModuleList(
            [Ops.get_string(value, "name", "")],
            true
          )
          Builtins.y2milestone(
            "loading module mod_%1 ...",
            Ops.get_string(value, "name", "")
          )
        end
      end

      nil
    end

    # Store host settings
    # @param [String] key string
    # @param [Hash] event map
    def HostStore(key, event)
      event = deep_copy(event)
      options = []
      Builtins.foreach(@host_options) do |key2, values|
        if Builtins.haskey(values, "DATA")
          #In main host SSL can't be used
          if Ops.get_string(values, "KEY", "") == "SSL"
            options = Builtins.add(
              options,
              {
                "KEY"          => "_SECTION",
                "SECTIONNAME"  => "IfDefine",
                "SECTIONPARAM" => "SSL",
                "VALUE"        => Ops.get_list(values, "DATA", []),
                "OVERHEAD"     => Ops.get_string(values, "OVERHEAD", "")
              }
            )
            Builtins.y2milestone("SSL section - %1", options)
          end

          if Ops.get_string(values, "KEY", "") == "Directory"
            options = Builtins.add(
              options,
              {
                "KEY"          => "_SECTION",
                "SECTIONNAME"  => "Directory",
                "SECTIONPARAM" => Ops.get_string(values, "VALUE", ""),
                "VALUE"        => Ops.get_list(values, "DATA", []),
                "OVERHEAD"     => Ops.get_string(values, "OVERHEAD", "")
              }
            )
            Builtins.y2milestone("Directory section - %1", values)
          end

          if Ops.get_string(values, "KEY", "") == "mod_userdir.c"
            options = Builtins.add(
              options,
              {
                "KEY"          => "_SECTION",
                "SECTIONNAME"  => "IfModule",
                "SECTIONPARAM" => "mod_userdir.c",
                "VALUE"        => Ops.get_list(values, "DATA", []),
                "OVERHEAD"     => Ops.get_string(values, "OVERHEAD", "")
              }
            )
            Builtins.y2milestone("Directory section - %1", values)
          end
        else
          options = Builtins.add(options, values)
          Builtins.y2milestone("Global section - %1", values)
        end
      end

      options = Builtins.filter(options) { |option| option != nil }

      # for all host options check whether module from directive is loaded
      Builtins.foreach(options) do |values|
        checkLoadedModuleFor(Ops.get_string(values, "KEY", ""))
      end

      if @currenthost != "main"
        options = Builtins.add(
          options,
          {
            "KEY"   => "HostIP",
            "VALUE" => Convert.to_string(
              UI.QueryWidget(Id(:virtual_host), :Value)
            )
          }
        )
        options = Builtins.add(
          options,
          {
            "KEY"   => "VirtualByName",
            "VALUE" => UI.QueryWidget(Id(:resolution), :Value) == :name_based ? "1" : "0"
          }
        )
      end
      YaST::HTTPDData.ModifyHost(@currenthost, options)

      setHostOptions(nil)

      nil
    end

    # Set host options
    # @param [Hash <Fixnum, Hash{String => Object>}] new_options map < integer, map < string,any > >
    def setHostOptions(new_options)
      new_options = deep_copy(new_options)
      @host_options = deep_copy(new_options)

      nil
    end

    # Function for getting contents of the default host table
    # @param [Hash] descr map description map of the table
    # @return [Array] of items for the table
    def HostTableContents(descr)
      descr = deep_copy(descr)
      if @host_options == nil
        # fill the data
        @option_counter = 0
        @host_options = {}
        @deleted_options = []
        res = []

        # flags, whether the required entries are present
        servername = false
        serveradmin = false
        documentroot = false

        host = YaST::HTTPDData.GetHost(@currenthost)
        Builtins.foreach(host) do |option|
          key = Ops.get_string(option, "KEY", "unknown")
          servername = true if key == "ServerName"
          serveradmin = true if key == "ServerAdmin"
          documentroot = true if key == "DocumentRoot"
          if key == "_SECTION" &&
              Ops.get_string(option, "SECTIONNAME", "") == "Directory"
            Ops.set(
              @host_options,
              @option_counter,
              {
                "KEY"      => "Directory",
                "VALUE"    => Ops.get_string(option, "SECTIONPARAM", ""),
                "DATA"     => Ops.get_list(option, "VALUE", []),
                "OVERHEAD" => Ops.get_string(option, "OVERHEAD", "")
              }
            )
            res = Builtins.add(res, @option_counter)
            @option_counter = Ops.add(@option_counter, 1)
          end
          if key == "_SECTION" &&
              Ops.get_string(option, "SECTIONPARAM", "") == "SSL"
            Ops.set(
              @host_options,
              @option_counter,
              {
                "KEY"      => "SSL",
                "VALUE"    => "",
                "DATA"     => Ops.get_list(option, "VALUE", []),
                "OVERHEAD" => Ops.get_string(option, "OVERHEAD", "")
              }
            )
            res = Builtins.add(res, @option_counter)
            @option_counter = Ops.add(@option_counter, 1)
          end
          # skip SECTIONS
          if key == "_SECTION"
            if Ops.get_string(option, "SECTIONNAME", "") == "IfModule"
              Ops.set(
                @host_options,
                @option_counter,
                {
                  "KEY"      => Ops.get_string(option, "SECTIONPARAM", ""),
                  "VALUE"    => "",
                  "DATA"     => Ops.get_list(option, "VALUE", []),
                  "OVERHEAD" => Ops.get_string(option, "OVERHEAD", "")
                }
              )
              res = Builtins.add(res, @option_counter)
              @option_counter = Ops.add(@option_counter, 1)
            else
              @option_counter = Ops.add(@option_counter, 1)
              next
            end
          # skip HostIP for default host
          elsif @currenthost == "main" && key == "HostIP"
            Ops.set(@host_options, @option_counter, option)
            @option_counter = Ops.add(@option_counter, 1)
            next
          else
            Ops.set(@host_options, @option_counter, option)
            res = Builtins.add(res, @option_counter)
            @option_counter = Ops.add(@option_counter, 1)
          end
        end


        # required entries
        if !servername
          Builtins.y2milestone("Adding missing ServerName")
          Ops.set(
            @host_options,
            @option_counter,
            { "KEY" => "ServerName", "VALUE" => "" }
          )
          res = Builtins.add(res, @option_counter)
          @option_counter = Ops.add(@option_counter, 1)
        end

        if !serveradmin
          Builtins.y2milestone("Adding missing ServerAdmin")
          Ops.set(
            @host_options,
            @option_counter,
            { "KEY" => "ServerAdmin", "VALUE" => "" }
          )
          res = Builtins.add(res, @option_counter)
          @option_counter = Ops.add(@option_counter, 1)
        end

        if !documentroot
          Builtins.y2milestone("Adding missing DocumentRoot")
          Ops.set(
            @host_options,
            @option_counter,
            { "KEY" => "DocumentRoot", "VALUE" => "" }
          )
          res = Builtins.add(res, @option_counter)
          @option_counter = Ops.add(@option_counter, 1)
        end
        return deep_copy(res)
      else
        # just generate the list of ids
        return Builtins.maplist(@host_options) { |id, value| id }
      end
    end

    # Function for getting contents of the default host table
    # @param [Hash] descr map description map of the table
    # @return [Array] of items for the table
    def SSLTableContents(descr)
      descr = deep_copy(descr)
      if @host_options == nil
        # fill the data
        @option_counter = 0
        @host_options = {}
        @deleted_options = []
        res = []

        host = YaST::HTTPDData.GetHost(@currenthost)
        Builtins.foreach(host) do |option|
          key = Ops.get_string(option, "KEY", "unknown")
          # skip non-SSL options
          if Ops.get_string(option, "KEY", "unknown") == "_SECTION" &&
              Ops.get_string(option, "SECTIONPARAM", "unknown") == "SSL"
            Builtins.foreach(Ops.get_list(option, "VALUE", [])) do |value|
              Ops.set(@host_options, @option_counter, value)
              res = Builtins.add(res, @option_counter)
              @option_counter = Ops.add(@option_counter, 1)
            end
          else
            if Ops.get_string(option, "KEY", "unknown") == "_SECTION" &&
                Ops.get_string(option, "SECTIONNAME", "unknown") == "Directory"
              Builtins.foreach(Ops.get_list(option, "VALUE", [])) do |value|
                if Ops.get_string(value, "KEY", "unknown") == "_SECTION" &&
                    Ops.get_string(value, "SECTIONPARAM", "unknown") == "SSL" &&
                    Ops.get_list(value, "VALUE", []) != []
                  Builtins.foreach(Ops.get_list(value, "VALUE", [])) do |directive|
                    found = false
                    Builtins.foreach(@host_options) do |key2, val|
                      found = true if val == directive
                    end
                    if found == false
                      Ops.set(@host_options, @option_counter, directive)
                      res = Builtins.add(res, @option_counter)
                      @option_counter = Ops.add(@option_counter, 1)
                    end
                  end
                end
              end
            end
            @option_counter = Ops.add(@option_counter, 1)
            next
          end
        end
        return deep_copy(res)
      else
        # just generate the list of ids
        return Builtins.maplist(@host_options) { |id, value| id }
      end
    end
    # Delete function of the global table
    # @param [Object] opt_id any option id of selected option
    # @param [String] opt_key any option key of selected option
    # @return [Boolean] true if was really deleted
    def HostTableEntryDelete(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      return false if !Confirm.DeleteSelected

      @host_options = Builtins.filter(@host_options) do |opt, value|
        opt != opt_id
      end

      @deleted_options = Builtins.add(
        @deleted_options,
        Convert.to_integer(opt_id)
      )

      HttpServer.modified = true
      true
    end

    #  Handler for editing default host. Handles additional buttons, like logs and modules.
    #  Rest is passed to TablePopup::TableHandle.
    #
    #  @param [String] key	the key modified
    #  @param [Hash] event	event description
    #  @return [Symbol] 	the result of the handling
    def handleHostTable(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventType", "") == "WidgetEvent" &&
          Ops.get(event, "WidgetID") == :_tp_add
        @dir_value = ""
      else
        @dir_value = Ops.get_string(
          @host_options,
          [
            Convert.to_integer(UI.QueryWidget(:_tp_table, :CurrentItem)),
            "VALUE"
          ],
          ""
        )
      end

      # handle menu button entries
      # 	if( event["ID"]:nil == `show_access_log ) {
      # 	    return showAccessLogPopup( key, event );
      # 	}
      # 	else if( event["ID"]:nil == `show_error_log ) {
      # 	    return showErrorLogPopup( key, event );
      # 	}
      res = TablePopup.TableHandleWrapper(key, event)
      # 	if (update_contents)
      # 	{
      # 	    update_contents = false;
      # 	    TablePopup::TableInit( hostwidget, key);
      # 	}
      res
    end

    # Fallback initialization function of a table entry / popup
    # @param [Object] option_id any unique option id
    # @param [String] option_type string the name of the key in the option list description
    def DefaultHostPopupInit(option_id, option_type)
      option_id = deep_copy(option_id)
      value = Ops.get_string(
        @host_options,
        [Convert.to_integer(option_id), "VALUE"],
        ""
      )

      if option_type == "VirtualByName"
        UI.ChangeWidget(Id(option_type), :CurrentButton, value)
      elsif option_type == "ServerName"
        UI.ChangeWidget(
          Id(option_type),
          :Value,
          Punycode.DecodeDomainName(Convert.to_string(value))
        )
      else
        UI.ChangeWidget(Id(option_type), :Value, value)
      end

      nil
    end

    # Fallback store function of a table entry / popup
    # @param [Object] option_id any option id
    # @param [String] option_type string option key
    def DefaultHostPopupStore(option_id, option_type)
      option_id = deep_copy(option_id)
      property = option_type == "VirtualByName" ? :CurrentButton : :Value

      if option_id == nil
        # new option
        Ops.set(@host_options, @option_counter, { "KEY" => option_type })
        option_id = @option_counter
        @option_counter = Ops.add(@option_counter, 1)
      end
      value = Convert.to_string(UI.QueryWidget(Id(option_type), property))
      value = Punycode.EncodeDomainName(value) if option_type == "ServerName"
      Ops.set(@host_options, [Convert.to_integer(option_id), "VALUE"], value)
      HttpServer.modified = true

      nil
    end

    # Fallback summary function of a table entry / popup
    # @param [Object] option_id any option unique id
    # @param [String] option_type string option type
    # @return [String] table entry summary
    def HostTableEntrySummary(option_id, option_type)
      option_id = deep_copy(option_id)
      if option_type == "VirtualByName"
        if Ops.get_string(
            @host_options,
            [Convert.to_integer(option_id), "VALUE"],
            ""
          ) == "1"
          # translators: table entry text for name-based vhosts
          return _("Resolution via HTTP Headers")
        else
          # translators: table entry text for IP-based vhosts
          return _("Resolution via IP Address Used")
        end
      elsif option_type == "Directory"
        return Ops.add(
          Ops.get_string(
            @host_options,
            [Convert.to_integer(option_id), "VALUE"],
            ""
          ),
          "..."
        )
      elsif option_type == "ServerName"
        return Punycode.DecodeDomainName(
          Ops.get_string(
            @host_options,
            [Convert.to_integer(option_id), "VALUE"],
            ""
          )
        )
      else
        return Ops.get_string(
          @host_options,
          [Convert.to_integer(option_id), "VALUE"],
          ""
        )
      end
    end

    # Store SSL type
    # @param [Object] option_id any
    # @param [String] option_type string
    def SSLTypeStore(option_id, option_type)
      option_id = deep_copy(option_id)
      # it is a radio button group
      Ops.set(
        @host_options,
        [Convert.to_integer(option_id), "VALUE"],
        UI.QueryWidget(Id(option_type), :CurrentButton)
      )
      HttpServer.modified = true

      nil
    end

    # Contents of host table
    # @param [Hash] descr map
    # @return [Array] host contents
    def DirTableContents(descr)
      descr = deep_copy(descr)
      if @host_options == nil
        # fill the data
        @option_counter = 0
        @host_options = {}
        @deleted_options = []
        res = []

        host = YaST::HTTPDData.GetHost(@currenthost)
        Builtins.foreach(host) do |option|
          key = Ops.get_string(option, "KEY", "unknown")
          if Ops.get_string(option, "KEY", "unknown") == "_SECTION" &&
              Ops.get_string(option, "SECTIONNAME", "unknown") == "Directory" &&
              Ops.get_string(option, "SECTIONPARAM", "unknown") == @dir_value
            Builtins.foreach(Ops.get_list(option, "VALUE", [])) do |value|
              if !(Ops.get_string(value, "KEY", "") == "_SECTION" &&
                  Ops.get_string(value, "SECTIONPARAM", "") == "SSL")
                Ops.set(@host_options, @option_counter, value)
                res = Builtins.add(res, @option_counter)
                @option_counter = Ops.add(@option_counter, 1)
              end
            end
          else
            @option_counter = Ops.add(@option_counter, 1)
            next
          end
        end
        return deep_copy(res)
      else
        # just generate the list of ids
        return Builtins.maplist(@host_options) { |id, value| id }
      end
    end

    # ************************************ modules list ***************************

    # Initialize function of a widget
    # @param [String] key any widget key of widget that is processed
    def initModules(key)
      known = YaST::HTTPDData.GetKnownModules
      modules = YaST::HTTPDData.GetModuleList
      index = -1
      # create temporary list of maps from modules
      listmodules = Builtins.maplist(modules) do |name|
        Builtins.mapmap(
          {
            "default"  => "1",
            "name"     => name,
            "summary"  => _("unknown"),
            "requires" => ""
          }
        ) { |k, v| { k => v } }
      end
      # add to known modules list modules from temporary list
      Builtins.foreach(listmodules) do |mapmodules|
        finded = false
        Builtins.foreach(known) do |mapknownmodules|
          #translators: list of known and unknown modules
          if Ops.get_locale(mapknownmodules, "name", _("unknown")) ==
              Ops.get_locale(mapmodules, "name", _("unknown"))
            finded = true
          end
        end
        known = Builtins.add(known, mapmodules) if !finded
      end
      items = Builtins.maplist(known) do |mod|
        index = Ops.add(index, 1)
        # translators: server module status unknown
        name = Ops.get_locale(mod, "name", _("unknown"))
        #	if ((mod["default"]:"0" == "1") && (!contains(modules, name))) YaST::HTTPDData::ModifyModuleList ([name], true);
        # translators: server module status
        Item(
          Id(index),
          name,
          Builtins.contains(modules, name) ?
            _("Enabled") :
            # translators: server module status
            _("Disabled"),
          Ops.get_string(mod, "summary", "")
        )
      end
      UI.ChangeWidget(Id(:modules), :Items, items)
      UI.SetFocus(Id(:modules))

      nil
    end

    def validateModules(id, key)
      key = deep_copy(key)
      valid = true
      selected = []
      Builtins.foreach(
        Convert.convert(
          UI.QueryWidget(:modules, :Items),
          :from => "any",
          :to   => "list <term>"
        )
      ) do |i|
        if Ops.get_string(i, 2, "") == _("Enabled")
          selected = Builtins.add(selected, Ops.get_string(i, 1, ""))
        end
      end
      all_modules = {}
      Builtins.foreach(YaST::HTTPDData.GetKnownModules) do |row|
        Ops.set(
          all_modules,
          Ops.get_string(row, "name", ""),
          Builtins.remove(row, "name")
        )
      end
      Builtins.foreach(selected) do |mod|
        require = Ops.get_string(all_modules, [mod, "requires"], "")
        if Ops.greater_than(Builtins.size(require), 0)
          if !Builtins.contains(selected, require)
            message = Builtins.sformat(
              "%1:\n %2 %3 %4\n%5",
              _("Modules dependency problem"),
              mod,
              _("requires"),
              require,
              _("Enable required module or disable first one.")
            )
            Popup.Error(message)
            Builtins.y2warning("Error message: %1", message)
            valid = false
          end
        end
      end
      valid
    end

    # Handle function of a widget
    # @param [String] key any widget key of widget that is processed
    # @param [Hash] event any event that occured
    # @return [Symbol] symbol for WS or nil
    def handleModules(key, event)
      event = deep_copy(event)
      UI.SetFocus(Id(:modules))
      if Ops.get(event, "ID") == :toggle
        ci = Convert.to_integer(UI.QueryWidget(Id(:modules), :CurrentItem))

        #	    string status = (string) select( (term) UI::QueryWidget( `id(`modules), `Item(ci) ), 2, _("Enabled") );
        status = Ops.get_locale(
          Convert.to_term(UI.QueryWidget(Id(:modules), term(:Item, ci))),
          2,
          _("Enabled")
        )
        #	    string name = (string) select( (term) UI::QueryWidget( `id(`modules), `Item(ci) ), 1, nil );
        name = Ops.get_string(
          Convert.to_term(UI.QueryWidget(Id(:modules), term(:Item, ci))),
          1,
          ""
        )
        Builtins.y2debug("Status of module: %1", status)
        if status == _("Enabled")
          status = _("Disabled")
        else
          status = _("Enabled")
        end
        UI.ChangeWidget(Id(:modules), term(:Item, ci, 1), status)
        Builtins.foreach(YaST::HTTPDData.GetKnownModules) do |mods|
          if name == Ops.get_string(mods, "name", "") && status == _("Enabled") &&
              Ops.get(mods, "exclude") != nil
            Builtins.foreach(Ops.get_list(mods, "exclude", [])) do |exclude|
              YaST::HTTPDData.ModifyModuleList([exclude], false)
              Builtins.foreach(
                Convert.to_list(UI.QueryWidget(Id(:modules), :Items))
              ) do |excl_row|
                if exclude == Ops.get_string(Convert.to_term(excl_row), 1, "")
                  row = Ops.get_integer(
                    Ops.get_term(Convert.to_term(excl_row), 0),
                    0
                  )
                  if row != nil
                    UI.ChangeWidget(
                      Id(:modules),
                      term(:Item, row, 1),
                      _("Disabled")
                    )
                  end
                end
              end
              Builtins.y2milestone(
                "Disabling module %1 excluded by %2",
                exclude,
                name
              )
            end
          end
        end
        YaST::HTTPDData.ModifyModuleList([name], status == _("Enabled"))
        HttpServer.modified = true
      elsif Ops.get(event, "ID") == :add_user
        module_dirs = Builtins.sformat(
          "/usr/lib*/apache2/ /usr/lib*/apache2-%1/",
          PackageSystem.Installed("apache2-prefork") ? "prefork" : "worker"
        )
        # list of all installed modules
        all_modules = Builtins.splitstring(
          Ops.get_string(
            Convert.convert(
              SCR.Execute(
                path(".target.bash_output"),
                Builtins.sformat(
                  "ls %1|grep \".so$\"|cut -d. -f1|cut -d_ -f2-",
                  module_dirs
                )
              ),
              :from => "any",
              :to   => "map <string, any>"
            ),
            "stdout",
            ""
          ),
          "\n"
        )
        existing = Builtins.maplist(YaST::HTTPDData.GetKnownModules) do |mod|
          Ops.get_locale(mod, "name", _("unknown"))
        end
        # extract unknown modules from all installed
        unknown_modules = []
        Builtins.foreach(all_modules) do |single_module|
          if !Builtins.contains(existing, single_module) && single_module != ""
            unknown_modules = Builtins.add(unknown_modules, single_module)
          end
        end
        Builtins.y2milestone("List of new modules %1", unknown_modules)
        UI.OpenDialog(
          VBox(
            # translators: combo box for selsect module from installed unknown modules
            ComboBox(Id(:mod), _("New Module &Name:"), unknown_modules),
            ButtonBox(
              PushButton(Id(:ok), Opt(:default), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            )
          )
        )

        UI.SetFocus(Id(:mod))

        ret = Convert.to_symbol(UI.UserInput)

        if ret == :ok
          mod = String.CutBlanks(
            Convert.to_string(UI.QueryWidget(Id(:mod), :Value))
          )
          if mod == ""
            # translators: error message
            Report.Error(_("A name for the module to add is required."))
          elsif Builtins.contains(existing, mod)
            # translators: error message
            Report.Error(_("The module is already in the list."))
          else
            YaST::HTTPDData.ModifyModuleList([mod], true)
            HttpServer.modified = true
          end
        end
        UI.CloseDialog
        initModules(nil)
      end

      nil
    end

    # ************************************ listen settings ************************

    # Initialize function of a widget
    # @param [String] key any widget key of widget that is processed
    def initListenSettings(key)
      id = -1
      listen = YaST::HTTPDData.GetCurrentListen
      Builtins.y2milestone("Listen: %1", listen)
      items = Builtins.maplist(listen) do |litem|
        id = Ops.add(id, 1)
        listen2item(litem, id)
      end
      UI.ChangeWidget(Id(:listen), :Items, items)

      # enable/disable buttons - at least single Listen must be present
      UI.ChangeWidget(
        Id(:delete),
        :Enabled,
        Ops.greater_than(Builtins.size(listen), 1)
      )

      # set focus
      UI.SetFocus(Id(:listen))

      nil
    end

    # Handle function of a widget
    # @param [String] key any widget key of widget that is processed
    # @param [Hash] event map event that occured
    # @return [Symbol] symbol for WS or nil
    def handleListenSettings(key, event)
      event = deep_copy(event)
      UI.SetFocus(Id(:listen))
      current = Convert.to_integer(UI.QueryWidget(Id(:listen), :CurrentItem))
      currentitem = current != nil ?
        Convert.to_term(UI.QueryWidget(Id(:listen), term(:Item, current))) :
        Item(-1, "", "")
      network = Ops.get_string(currentitem, 1)
      # translators: all network addresses Listen type
      network = "" if network == _("All Addresses")
      port = Ops.get_string(currentitem, 2, "")

      if Ops.get(event, "ID") == :add
        # translators: all network addresses Listen type
        res = AskListen(_("All Addresses"), "")
        if res != nil
          if false # FIXME: CreateListen error reporting
            # translators: error message for adding a new Listen statement
            Popup.Error(
              Builtins.sformat(_("The entry '%1' already exists."), res)
            )
          else
            #		  if (IP::Check6(res["ADDRESS"]:"")) res["ADDRESS"]=sformat("[%1]", res["ADDRESS"]:"");
            YaST::HTTPDData.CreateListen(
              Builtins.tointeger(Ops.get(res, "PORT", "80")),
              Builtins.tointeger(Ops.get(res, "PORT", "80")),
              Ops.get(res, "ADDRESS", "")
            )
            Builtins.y2internal("get %1", YaST::HTTPDData.GetCurrentListen)
            HttpServer.modified = true
          end
        end
      elsif Ops.get(event, "ID") == :delete
        validate = Builtins.size(YaST::HTTPDData.GetCurrentListen) != 0

        Builtins.y2debug("Validation result: %1", validate)

        if !validate
          # translators: error message
          Popup.Error(
            _(
              "The list of the ports to which the server should\nlisten cannot be empty."
            )
          )
          return nil
        end
        # remove the entry
        YaST::HTTPDData.DeleteListen(
          Builtins.tointeger(port),
          Builtins.tointeger(port),
          network
        )
        HttpServer.modified = true
      elsif Ops.get(event, "ID") == :edit
        res = AskListen(network, port)
        if res != nil
          # remove the old one
          YaST::HTTPDData.DeleteListen(
            Builtins.tointeger(port),
            Builtins.tointeger(port),
            network
          )
          # create the new one
          YaST::HTTPDData.CreateListen(
            Builtins.tointeger(Ops.get(res, "PORT", "80")),
            Builtins.tointeger(Ops.get(res, "PORT", "80")),
            Ops.get(res, "ADDRESS", "")
          )
          HttpServer.modified = true
        end
      end

      initListenSettings(nil)

      nil
    end


    # ************************************ server status ***********************

    # Initialize function of a widget
    # @param [String] key any widget key of widget that is processed
    def initServiceStatus(key)
      if YaST::HTTPDData.GetService != nil && YaST::HTTPDData.GetService
        UI.ChangeWidget(Id("enabled"), :Value, true)
      else
        UI.ChangeWidget(Id("disabled"), :Value, true)
      end

      nil
    end

    # Store function of a widget
    # @param [String] key any widget key of widget that is processed
    # @param [Hash] event map event that occured
    def storeServiceStatus(key, event)
      event = deep_copy(event)
      YaST::HTTPDData.ModifyService(
        Convert.to_boolean(UI.QueryWidget(Id("enabled"), :Value))
      )
      HttpServer.modified = true

      nil
    end
    # Handling service status
    # @param [String] key string
    # @param [Hash] event map
    # @return [Symbol] (`overview_table, `edit. `menu)
    def handleServiceStatus(key, event)
      event = deep_copy(event)
      # enable/disable overview widget
      enable = Convert.to_boolean(UI.QueryWidget(Id("enabled"), :Value))

      UI.ChangeWidget(:overview_table, :Enabled, enable)
      UI.ChangeWidget(:edit, :Enabled, enable)
      UI.ChangeWidget(:menu, :Enabled, enable)

      nil
    end

    # *********************** Wizard Dialog 1 Widgets *****************************************

    # Initialize open port
    # @param [String] key string
    def initOpenPort(key)
      port = nil

      Builtins.foreach(YaST::HTTPDData.GetCurrentListen) do |listens|
        port = Ops.get_string(listens, "PORT", "80") if port != "80"
      end
      port = "80" if port == nil
      Builtins.y2milestone("Port finally :  %1", port)
      UI.ChangeWidget(Id(key), :Value, port)

      nil
    end

    # Handling open port
    # @param [String] key string
    # @param [Hash] event map
    # @return [Symbol] nil
    def handleOpenPort(key, event)
      event = deep_copy(event)
      nil
    end

    # Validation open port
    # @param [String] key string
    # @param [Hash] event string
    # @return [Boolean] validate open port
    def validateOpenPort(key, event)
      event = deep_copy(event)
      value = Convert.to_string(UI.QueryWidget(Id(key), :Value))
      Builtins.y2milestone("validate open port ... %1", value)
      if !Builtins.regexpmatch(value, "^[ \t]*[0-9]+[ \t]*$")
        #translators: popup error
        Popup.Error(_("Invalid port number."))
        UI.SetFocus(Id(key))
        return false
      else
        return true
      end
    end

    # Initialize listen interfaces
    # @param [String] key string

    def initListenInterfaces(key)
      Builtins.y2milestone("Initializing Listen Interfaces ... %1", key)
      all = false
      Builtins.foreach(YaST::HTTPDData.GetCurrentListen) do |listens|
        all = true if Ops.get_string(listens, "ADDRESS", "") == ""
      end

      ips = Builtins.maplist(HttpServer.ip2device) do |ip, dev|
        if all
          next Item(ip, true)
        else
          checked = false
          Builtins.foreach(YaST::HTTPDData.GetCurrentListen) do |listens|
            checked = true if Ops.get_string(listens, "ADDRESS", "") == ip
          end
          next Item(ip, checked)
        end
      end
      #translators: multi selection box
      UI.ReplaceWidget(
        Id(@mode_replace_point_key),
        MultiSelectionBox(Id("multi_sel_box"), _("&Listen on Interfaces"), ips)
      )

      nil
    end

    #
    # @param [String] key string
    # @param [Hash] event map
    # @return [Boolean] validate interfaces
    def validateListenInterfaces(key, event)
      event = deep_copy(event)
      if Ops.less_than(
          Builtins.size(
            Convert.to_list(UI.QueryWidget(Id("multi_sel_box"), :SelectedItems))
          ),
          1
        )
        #translators: popup error - multi selection box with server network adresses
        Popup.Error(_("At least one interface must be selected."))
        UI.SetFocus(Id(key))
        return false
      else
        return true
      end
    end
    def initScriptModules(key)
      modules = YaST::HTTPDData.GetModuleList
      enable_php = Builtins.contains(modules, "php#{YaST::HTTPDData.PhpVersion}")
      enable_perl = Builtins.contains(modules, "perl")
      enable_python = Builtins.contains(modules, "python")

      UI.ReplaceWidget(
        Id(:scr_mod_replace),
        HBox(
          HSpacing(6),
          VBox(
            VSpacing(3), #translators: checkbox - support for php script language
            Left(
              CheckBox(
                Id(:scr_mod_php),
                _("Enable &PHP Scripting"),
                enable_php
              )
            ),
            VSpacing(1), #translators: checkbox - support for perl script language
            Left(
              CheckBox(
                Id(:scr_mod_perl),
                _("Enable P&erl Scripting"),
                enable_perl
              )
            ),
            VSpacing(1), #translators: checkbox - support for python script language
            Left(
              CheckBox(
                Id(:scr_mod_python),
                _("Enable P&ython Scripting"),
                enable_python
              )
            ),
            #                        `VSpacing(1),   //translators: checkbox - support for ruby script language
            #                      `Left(`CheckBox(`id(`scr_mod_ruby), _("Enable &Ruby Scripting"), enable_ruby)),
            VSpacing(2)
          )
        )
      )
      Builtins.y2milestone("initializing script modules")

      nil
    end

    # *********************** Wizard Dialog 5 Widgets *****************************************

    # Handler for expert configuration
    # @param [String] key string
    # @param [Hash] event map
    # @return [Symbol] (nil, `expert)
    def handleExpertConf(key, event)
      event = deep_copy(event)
      if Ops.get(event, "ID") == "expert_conf"
        @init_tab = "listen"
        return :expert
      else
        return nil
      end
    end
    def getServiceAutoStart
      if YaST::HTTPDData.GetService != nil && YaST::HTTPDData.GetService
        return true
      else
        return false
      end
    end
    def setServiceAutoStart(status)
      YaST::HTTPDData.ModifyService(status)

      nil
    end
    def initSummaryText(key)
      UI.ReplaceWidget(
        Id(:summary_text_rp),
        RichText(Ops.get_string(HttpServer.Summary, 0, "error"))
      )

      nil
    end

    publish :variable => :currenthost, :type => "string"
    publish :variable => :init_tab, :type => "string"
    publish :function => :get_host_value, :type => "any (string, list <map <string, any>>, any)"
    publish :function => :set_host_value, :type => "list <map <string, any>> (string, list <map <string, any>>, any)"
    publish :function => :validate_servername, :type => "boolean (string)"
    publish :function => :validate_serverip, :type => "boolean (any, any, map)"
    publish :function => :validate_server, :type => "boolean (string, list <map <string, any>>)"
    publish :function => :validate_server_fnc, :type => "boolean (string, map)"
    publish :function => :ReloadServer, :type => "void ()"
    publish :function => :HostsInit, :type => "void (string)"
    publish :function => :HostsHandle, :type => "symbol (string, map)"
    publish :function => :HostsContents, :type => "list (map)"
    publish :function => :HostsDelete, :type => "boolean (any, string)"
    publish :function => :HostName, :type => "string (any, string)"
    publish :function => :HostDocumentRootSummary, :type => "string (any, string)"
    publish :function => :HostIsDefault, :type => "boolean (any, string)"
    publish :function => :handleHostTable, :type => "symbol (string, map)"
    publish :function => :HostStore, :type => "void (string, map)"
    publish :function => :HostTableContents, :type => "list (map)"
    publish :function => :DefaultHostPopupInit, :type => "void (any, string)"
    publish :function => :DefaultHostPopupStore, :type => "void (any, string)"
    publish :function => :HostTableEntrySummary, :type => "string (any, string)"
    publish :function => :HostTableEntryDelete, :type => "boolean (any, string)"
    publish :function => :HostId2Key, :type => "string (map, any)"
    publish :function => :initModules, :type => "void (string)"
    publish :function => :handleModules, :type => "symbol (string, map)"
    publish :function => :validateModules, :type => "boolean (string, map)"
    publish :function => :initListenSettings, :type => "void (string)"
    publish :function => :handleListenSettings, :type => "symbol (string, map)"
    publish :function => :initServiceStatus, :type => "void (string)"
    publish :function => :handleServiceStatus, :type => "symbol (string, map)"
    publish :function => :storeServiceStatus, :type => "void (string, map)"
    publish :function => :initAdaptFirewall, :type => "void (string)"
    publish :function => :storeAdaptFirewall, :type => "void (string, map)"
    publish :function => :initOpenPort, :type => "void (string)"
    publish :function => :handleOpenPort, :type => "symbol (string, map)"
    publish :function => :validateOpenPort, :type => "boolean (string, map)"
    publish :function => :initListenInterfaces, :type => "void (string)"
    publish :function => :validateListenInterfaces, :type => "boolean (string, map)"
    publish :function => :handleExpertConf, :type => "symbol (string, map)"
    publish :function => :handleBooting, :type => "symbol (string, map)"
    publish :function => :getHostOptions, :type => "map (boolean)"
    publish :function => :setHostOptions, :type => "void (map <integer, map <string, any>>)"
    publish :variable => :popups, :type => "map <string, map>"
    publish :function => :HostInit, :type => "void (string)"
    publish :variable => :hostwidget, :type => "map <string, any>"
    publish :function => :handleSSLTable, :type => "symbol (string, map)"
    publish :function => :SSLTableContents, :type => "list (map)"
    publish :function => :SSLInit, :type => "void (string)"
    publish :function => :SSLStore, :type => "void (string, map)"
    publish :function => :SSLTypeStore, :type => "void (any, string)"
    publish :function => :DirInit, :type => "void (string)"
    publish :function => :handleDirTable, :type => "symbol (string, map)"
    publish :function => :getDirOptions, :type => "map ()"
    publish :function => :DirTableContents, :type => "list (map)"
    publish :function => :DirStore, :type => "void (string, map)"
    publish :function => :DirPopupInit, :type => "void (any, string)"
    publish :function => :initVhostRes, :type => "void (string)"
    publish :function => :initVhostId, :type => "void (string)"
    publish :function => :handleVhostId, :type => "symbol (string, map)"
    publish :function => :validateVhostId, :type => "boolean (string, map)"
    publish :function => :storeVhostId, :type => "void (string, map)"
    publish :function => :handleVhostRest, :type => "symbol (string, map)"
    publish :function => :validateVhostRes, :type => "boolean (string, map)"
    publish :function => :initVhostDetails, :type => "void (string)"
    publish :function => :handleVhostDetails, :type => "symbol (string, map)"
    publish :function => :storeVhostDetails, :type => "void (string, map)"
    publish :variable => :widgets, :type => "map <string, map <string, any>>"
    publish :function => :listen2item, :type => "term (map <string, any>, integer)"
  end

  HttpServerWidgets = HttpServerWidgetsClass.new
  HttpServerWidgets.main
end
