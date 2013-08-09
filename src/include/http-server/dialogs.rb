# encoding: utf-8

# File:	include/http-server/wizards.ycp
# Package:	Configuration of http-server
# Summary:	Wizards definitions
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
module Yast
  module HttpServerDialogsInclude
    def initialize_http_server_dialogs(include_target)
      textdomain "http-server"

      Yast.import "YaST::HTTPDData"
      Yast.import "HttpServer"
      Yast.import "HttpServerWidgets"

      Yast.import "Mode"
      Yast.import "Popup"
      Yast.import "ProductFeatures"
      Yast.import "Label"
      Yast.import "CWM"
      Yast.import "CWMTab"
      Yast.import "Wizard"
      Yast.import "Service"
      Yast.import "TablePopup"
      Yast.import "Package"


      @tabs_descr = {
        "listen"    => {
          "header"       => _("Listen Ports and Addresses"),
          "contents"     => HBox(
            HStretch(),
            HSpacing(1),
            VBox(
              "server_enable", #,
              #			    `VSpacing(1)
              #		            `VSpacing (1),
              "LISTEN",
              #			    `VSpacing (1),
              "firewall_adapt",
              #		            `VSpacing (1),
              "logs"
            ),
            #			`HSpacing (1),
            HStretch()
          ),
          "widget_names" => [
            "server_enable",
            "LISTEN",
            "firewall_adapt",
            "logs"
          ]
        },
        "modules"   => {
          "header"       => _("Server Modules"),
          "contents"     => HBox(
            HSpacing(1),
            VBox(VSpacing(1), "MODULES", VSpacing(1)),
            HSpacing(1)
          ),
          "widget_names" => ["MODULES"]
        },
        "main_host" => {
          "header"       => _("Main Host"),
          "contents"     => HBox(
            HSpacing(1),
            VBox(VSpacing(1), "MAIN_HOST", VSpacing(1)),
            HSpacing(1)
          ),
          "widget_names" => ["MAIN_HOST"]
        },
        "hosts"     => {
          "header"       => _("Hosts"),
          "contents"     => HBox(
            HSpacing(1),
            VBox(
              VSpacing(1), #, `PushButton( `id( `set_default ), _("Set as De&fault") )
              "HOSTS",
              #`PushButton( `id( `set_default ), _("Set as De&fault") ),
              VSpacing(1)
            ),
            HSpacing(1)
          ),
          "widget_names" => ["HOSTS"]
        }
      }

      @descr = []
    end

    # Ask for confirmation (always)
    # @return true if abort is confirmed
    def ReallyAbortAlways
      Popup.ReallyAbort(true)
    end

    # Abort dialog
    # @return [Boolean] do abort
    def Abort
      !HttpServer.modified || Popup.ReallyAbort(true)
    end

    # Run server overview dialog
    # @return [Symbol] for wizard sequencer
    def OverviewDialog
      caption = _("HTTP Server Configuration")
      #    if (HttpServer::firewall_first) tabs_descr["listen", "widget_names"]= [ "server_enable", "LISTEN", "logs" ];
      widget_descr = {
        "tab" => CWMTab.CreateWidget(
          {
            "tab_order"    => ["listen", "modules", "main_host", "hosts"],
            "tabs"         => @tabs_descr,
            "widget_descr" => HttpServerWidgets.widgets,
            "initial_tab"  => HttpServerWidgets.init_tab,
            "tab_help"     => ""
          }
        )
      }
      contents = VBox("tab")

      w = CWM.CreateWidgets(
        ["tab"],
        Convert.convert(
          widget_descr,
          :from => "map",
          :to   => "map <string, map <string, any>>"
        )
      )
      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.FinishButton
      )
      Wizard.RestoreAbortButton
      Wizard.DisableBackButton

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )

      ret
    end


    # Run single host configuration dialog
    # @return [Symbol] for wizard sequencer
    def HostDialog
      w = CWM.CreateWidgets(["host", "vhost_res"], HttpServerWidgets.widgets)
      contents = HBox(
        HSpacing(1),
        VBox(
          VSpacing(1),
          Ops.get_term(w, [0, "widget"]) { VSpacing(1) },
          Ops.get_term(w, [1, "widget"]) { VSpacing(1) }
        ),
        HSpacing(1)
      )

      # translators: dialog caption
      caption = Builtins.sformat(
        _("Host '%1' Configuration"),
        # translators: human-readable "default host"
        HttpServerWidgets.currenthost == "main" ?
          _("Main Host") :
          HttpServerWidgets.get_host_value(
            "ServerName",
            YaST::HTTPDData.GetHost(HttpServerWidgets.currenthost),
            HttpServerWidgets.currenthost
          )
      )

      help = CWM.MergeHelps(w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.OKButton
      )

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      HttpServerWidgets.setHostOptions(nil) if ret == :back
      ret
    end


    # Run virtual host list dialog
    # @return [Symbol] for wizard sequencer
    def HostsDialog
      w = CWM.CreateWidgets(["hosts"], HttpServerWidgets.widgets)
      contents = HBox(
        HSpacing(1),
        VBox(VSpacing(1), Ops.get_term(w, [0, "widget"]) { VSpacing(0) }, VSpacing(
          1
        )),
        HSpacing(1)
      )

      # dialog caption
      caption = _("Configured Hosts")
      help = CWM.MergeHelps(w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.OKButton
      )

      CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
    end
    # Return wizard for adding new virtual host
    # @return [Symbol] (`browse, `abort, `cancel, `next)
    def AddHost
      w = CWM.CreateWidgets(
        ["vhost_id", "vhost_res"],
        HttpServerWidgets.widgets
      )
      contents = HBox(
        HSpacing(0.5),
        VBox(
          Ops.get_term(w, [0, "widget"]) { VSpacing(0) },
          VSpacing(1),
          Ops.get_term(w, [1, "widget"]) { VSpacing(0) },
          HSpacing(0.5)
        )
      )

      # translators: dialog caption
      caption = _("New Host Information")

      help = Ops.get_string(@HELPS, "add_host_general", "")


      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.NextButton
      )

      CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
    end

    # Set virtual host options
    # @return [Symbol] from host widget
    def SetVHostOptions
      w = CWM.CreateWidgets(["vhost_details"], HttpServerWidgets.widgets)
      contents = HBox(
        HSpacing(0.5),
        VBox(Ops.get_term(w, [0, "widget"]) { VSpacing(0) }, HSpacing(0.5))
      )

      # translators: dialog caption
      caption = _("Virtual Host Details")

      help = Ops.get_string(@HELPS, "set_vhost", "")


      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.NextButton
      )

      CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
    end

    # Run host SSL dialog
    # @return [Symbol] for wizard sequencer
    def SSLDialog
      w = CWM.CreateWidgets(["ssl"], HttpServerWidgets.widgets)
      contents = HBox(
        HSpacing(1),
        VBox(VSpacing(1), Ops.get_term(w, [0, "widget"]) { VSpacing(0) }, VSpacing(
          1
        )),
        HSpacing(1)
      )

      # translators: dialog caption, %1 is the host name
      caption = Builtins.sformat(
        _("SSL Configuration for '%1'"),
        # translators: human-readable "default host"
        HttpServerWidgets.currenthost == "main" ?
          _("Default Host") :
          HttpServerWidgets.get_host_value(
            "ServerName",
            YaST::HTTPDData.GetHost(HttpServerWidgets.currenthost),
            HttpServerWidgets.currenthost
          )
      )

      help = CWM.MergeHelps(w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.OKButton
      )
      if ProductFeatures.GetFeature("globals", "ui_mode") != "simple"
        UI.ReplaceWidget(
          Id(:_tp_table_repl),
          #translators: pop up menu
          MenuButton(
            _("Certificates"),
            [
              #translators: Certificates pop-up menu item
              Item(Id(:import_certificate), _("&Import Server Certificate...")),
              #translators: Certificates pop-up menu item
              Item(Id(:common_certificate), _("&Use Common Server Certificate"))
            ]
          )
        )
      end

      CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
    end

    # Directory dialog
    # @return [Symbol] from directory widget
    def DirDialog
      w = CWM.CreateWidgets(["dir_name", "dir"], HttpServerWidgets.widgets)
      contents = HBox(
        HSpacing(0.5),
        VBox(
          Ops.get_term(w, [0, "widget"]) { VSpacing(0) },
          VSpacing(1),
          Ops.get_term(w, [1, "widget"]) { VSpacing(0) },
          HSpacing(0.5)
        )
      )

      # translators: dialog caption, %1 is the host name
      caption = Builtins.sformat(
        _("Dir Configuration for '%1'"),
        # translators: human-readable "default host"
        HttpServerWidgets.currenthost == "defaulthost" ?
          _("Default Host") :
          HttpServerWidgets.get_host_value(
            "ServerName",
            YaST::HTTPDData.GetHost(HttpServerWidgets.currenthost),
            HttpServerWidgets.currenthost
          )
      )

      help = CWM.MergeHelps(w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.OKButton
      )

      CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
    end
  end
end
