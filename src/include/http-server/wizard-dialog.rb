# encoding: utf-8

# File:	include/http-server/wizards.ycp
# Package:	Configuration of http-server
# Summary:	Wizards definitions
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
module Yast
  module HttpServerWizardDialogInclude
    def initialize_http_server_wizard_dialog(include_target)
      textdomain "http-server"
      Yast.import "HttpServerWidgets"
      Yast.import "Wizard"
      Yast.import "CWM"
      Yast.import "Label"
      Yast.import "HttpServer"
    end

    # Sequention used for determining on which ip adresses and port apache2 will listen and if firewall is enebled
    # whether to open firewall on this port.
    # @return [Symbol] (`back, `abort, `next)
    def WizardSequence1
      caption = _("HTTP Server Wizard (1/5)--Network Device Selection")
      contents = HBox(
        HStretch(),
        VBox(
          VSpacing(0.5),
          "open_port",
          VSpacing(0.5),
          "listen_interfaces",
          VSpacing(0.5),
          "firewall_adapt",
          VSpacing(8)
        ),
        HStretch()
      )
      widget_names = ["open_port", "listen_interfaces", "firewall_adapt"]
      w = CWM.CreateWidgets(widget_names, HttpServerWidgets.widgets)
      help = Ops.add(
        "<h3>" + _("Network Device Selection") + "</h3>",
        CWM.MergeHelps(w)
      )
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.NextButton
      )
      Wizard.DisableBackButton
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      event = {}
      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )

      if ret == :next
        #*	Save entred parameters to map
        if_all = Builtins.maplist(HttpServer.ip2device) { |ip, dev| ip }
        if_sel = Convert.convert(
          UI.QueryWidget(Id("multi_sel_box"), :SelectedItems),
          :from => "any",
          :to   => "list <string>"
        )
        Builtins.y2milestone("All interfaces : %1", if_all)
        Builtins.y2milestone(
          "going next %1",
          UI.QueryWidget(Id("open_port"), :Value)
        )
        Builtins.y2milestone("network interfaces : %1", if_sel)
        all = true
        finded = false
        Builtins.foreach(if_all) do |interface|
          finded = false
          Builtins.foreach(if_sel) do |selected|
            finded = true if selected == interface
          end
          all = false if !finded
        end
        Builtins.y2milestone("All: %1", all)
        # save port information
        Builtins.foreach(YaST::HTTPDData.GetCurrentListen) do |listens|
          YaST::HTTPDData.DeleteListen(
            Builtins.tointeger(Ops.get_string(listens, "PORT", "80")),
            Builtins.tointeger(Ops.get_string(listens, "PORT", "80")),
            Ops.get_string(listens, "ADDRESS", "")
          )
        end
        # save interface information
        if all == true
          YaST::HTTPDData.CreateListen(
            Builtins.tointeger(UI.QueryWidget(Id("open_port"), :Value)),
            Builtins.tointeger(UI.QueryWidget(Id("open_port"), :Value)),
            ""
          )
        else
          # save firewall open port information
          Builtins.foreach(if_sel) do |ip|
            YaST::HTTPDData.CreateListen(
              Builtins.tointeger(UI.QueryWidget(Id("open_port"), :Value)),
              Builtins.tointeger(UI.QueryWidget(Id("open_port"), :Value)),
              ip
            )
            Builtins.y2milestone("Listen on : %1", ip)
          end
          HttpServer.modified = true
        end
      end
      Builtins.y2milestone(
        "Listen string : %1",
        YaST::HTTPDData.GetCurrentListen
      )
      Convert.to_symbol(ret)
    end


    # Sequence to choose some script language modules
    # @return [Symbol] (`back, `abort, `next)
    def WizardSequence2
      caption = _("HTTP Server Wizard (2/5)--Modules")
      contents = Top("script_modules")

      widget_names = ["script_modules"]
      w = CWM.CreateWidgets(widget_names, HttpServerWidgets.widgets)
      help = Ops.add("<h3>" + _("Modules") + "</h3>", CWM.MergeHelps(w))
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.NextButton
      )
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      event = {}
      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      if ret == :next
        enable_php = Convert.to_boolean(
          UI.QueryWidget(Id(:scr_mod_php), :Value)
        )
        enable_perl = Convert.to_boolean(
          UI.QueryWidget(Id(:scr_mod_perl), :Value)
        )
        enable_python = Convert.to_boolean(
          UI.QueryWidget(Id(:scr_mod_python), :Value)
        )
        #        boolean enable_ruby=(boolean) UI::QueryWidget( `id(`scr_mod_ruby), `Value );

        Builtins.y2milestone("Saving script modules")
        Builtins.y2milestone("PHP support %1", enable_php)
        Builtins.y2milestone("Perl support %1", enable_perl)
        Builtins.y2milestone("Python support %1", enable_python)
        #	y2milestone("Ruby support %1", enable_ruby);
        # create list of all standard modules
        existing = Builtins.maplist(YaST::HTTPDData.GetKnownModules) do |mod|
          YaST::HTTPDData.ModifyModuleList(
            [Ops.get_locale(mod, "name", _("unknown"))],
            Ops.get_locale(mod, "default", _("0")) == "1"
          )
        end
        # add selected modules to that list
        YaST::HTTPDData.ModifyModuleList(["php#{YaST::HTTPDData.PhpVersion}"], enable_php)
        YaST::HTTPDData.ModifyModuleList(["perl"], enable_perl)
        YaST::HTTPDData.ModifyModuleList(["python"], enable_python)
        #        YaST::HTTPDData::ModifyModuleList ([ "ruby" ], enable_ruby);

        HttpServer.modified = true
      end
      Convert.to_symbol(ret)
    end


    # Sequence to configure default host parameters
    # @return [Symbol] (`back, `abort, `next)
    def WizardSequence3
      caption = _("HTTP Server Wizard (3/5)--Default Host")
      w = CWM.CreateWidgets(["MAIN_HOST"], HttpServerWidgets.widgets)
      contents = HBox(
        HSpacing(1),
        VBox(VSpacing(1), Ops.get_term(w, [0, "widget"]) { VSpacing(0) }, VSpacing(
          1
        )),
        HSpacing(1)
      )

      # dialog caption
      help = CWM.MergeHelps(w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.NextButton
      )
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      servername = Convert.to_string(
        HttpServerWidgets.get_host_value(
          "ServerName",
          YaST::HTTPDData.GetHost("main"),
          ""
        )
      )

      serveradmin = Convert.to_string(
        HttpServerWidgets.get_host_value(
          "ServerAdmin",
          YaST::HTTPDData.GetHost("main"),
          ""
        )
      )

      hostname = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), "/bin/hostname")
      )
      Builtins.y2milestone(
        "Hostname : %1",
        Ops.get_string(hostname, "stdout", "")
      )
      # if no ServerName or ServerAdmin readed from configuration file, the values based on machine hostname are used
      if Builtins.size(servername) == 0
        YaST::HTTPDData.ModifyHost(
          "main",
          HttpServerWidgets.set_host_value(
            "ServerName",
            YaST::HTTPDData.GetHost("main"),
            Ops.get_string(hostname, "stdout", "")
          )
        )
      end
      if Builtins.size(serveradmin) == 0
        YaST::HTTPDData.ModifyHost(
          "main",
          HttpServerWidgets.set_host_value(
            "ServerAdmin",
            YaST::HTTPDData.GetHost("main"),
            Ops.add("root@", Ops.get_string(hostname, "stdout", ""))
          )
        )
      end

      CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
    end


    # Sequence to cunfigure virtual hosts (add, remove, edit) and to change default host status
    # @return [Symbol] (`back, `abort, `next)
    def WizardSequence4
      caption = _("HTTP Server Wizard (4/5)--Virtual Hosts")

      w = CWM.CreateWidgets(["hosts"], HttpServerWidgets.widgets)
      contents = HBox(
        HSpacing(1),
        VBox(VSpacing(1), Ops.get_term(w, [0, "widget"]) { VSpacing(0) }, VSpacing(
          1
        )),
        HSpacing(1)
      )

      # dialog caption
      help = CWM.MergeHelps(w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.NextButton
      )
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
    end


    # Sequence to configure whether apache2 starts on boot or not (manually). Here is possible
    # save all settings and exit or start expert configuration.
    # @return [Symbol] (`back, `abort, `next)
    def WizardSequence5
      caption = _("HTTP Server Wizard (5/5)--Summary")

      contents = VBox("booting", "summary_text", "expert_conf")
      widget_names = ["booting", "summary_text", "expert_conf"]
      w = CWM.CreateWidgets(widget_names, HttpServerWidgets.widgets)
      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.FinishButton
      )
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      event = {}
      ret = CWM.Run(w, { :abort => fun_ref(method(:Abort), "boolean ()") })
      Builtins.y2milestone("Return value from 5.th dialog : %1", ret)
      Convert.to_symbol(ret)
    end
  end
end
