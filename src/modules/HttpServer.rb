# encoding: utf-8

# File:	modules/HttpServer.ycp
# Package:	Configuration of http-server
# Summary:	Data for configuration of http-server, input and output functions.
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#
# Representation of the configuration of http-server.
# Input and output routines.
require "yast"

module Yast
  class HttpServerClass < Module

    include Yast::Logger

    def main
      Yast.import "UI"
      textdomain "http-server"

      Yast.import "YaPI::HTTPD"
      Yast.import "YaST::HTTPDData"
      Yast.import "NetworkInterfaces"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Package"
      Yast.import "Service"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Directory"
      Yast.import "Popup"
      Yast.import "DnsServerAPI"
      Yast.import "NetworkService"
      Yast.import "SuSEFirewall"
      Yast.import "Confirm"
      Yast.import "SuSEFirewallServices"
      Yast.import "FileChanges"
      Yast.import "Label"

      # Abort function
      # return boolean return true if abort
      @AbortFunction = nil

      # Required packages
      @required_packages = ["apache2"]

      # Data was modified?
      @modified = false

      @configured = false

      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      @configured_dns = false

      Yast.include self, "http-server/routines.rb"

      # Mapping of IPs to network devices
      @ip2device = {}



      @files_to_check = [
        "/etc/sysconfig/apache2",
        "/etc/apache2/default-server.conf",
        "/etc/apache2/httpd.conf",
        "/etc/apache2/listen.conf",
        "/etc/apache2/vhosts.d/yast2_vhosts.conf"
      ]
    end

    IGNORED_FILES = ["vhost.template", "vhost-ssl.template"]
    APACHE_VHOSTS_DIR = "/etc/apache2/vhosts.d"

    def dynamic_files_to_check
      files = SCR.Read(path(".target.dir"), APACHE_VHOSTS_DIR)
      files.reject! { |f| IGNORED_FILES.include?(f) }
      files.map! { |f| File.join(APACHE_VHOSTS_DIR, f) }
      log.info "dynamic files: #{files}"
      files
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end

    def isWizardMode
      if {} ==
          SCR.Read(
            path(".target.stat"),
            Ops.add(Directory.vardir, "/http_server")
          )
        return true
      else
        return false
      end
    end

    def setWizardMode(w_mode)
      if w_mode == true
        SCR.Execute(
          path(".target.bash"),
          Builtins.sformat("rm %1%2", Directory.vardir, "/http_server")
        )
        Builtins.y2milestone("Set wizard mode on")
      else
        SCR.Write(
          path(".target.string"),
          Ops.add(Directory.vardir, "/http_server"),
          ""
        )
        Builtins.y2milestone("Set wizard mode off")
      end

      nil
    end

    # Read all http-server settings
    # @return true on success
    def Read
      # HttpServer read dialog caption
      caption = _("Initializing HTTP Server Configuration")

      steps = 4

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # translators: progress stage
          _("Check the environment"),
          # translators: progress stage
          _("Read Apache2 configuration"),
          # translators: progress stage
          _("Read network configuration")
        ],
        [
          # translators: progress step
          _("Checking the environment..."),
          # translators: progress step
          _("Reading Apache2 configuration..."),
          # translators: progress step
          _("Reading network configuration..."),
          # translators: progress finished
          _("Finished")
        ],
        ""
      )

      # check the environment
      return false if !Confirm.MustBeRoot
      return false if !NetworkService.RunningNetworkPopup

      return false if !NetworkService.ConfirmNetworkManager
      Progress.NextStep


      # check rpms
      required = deep_copy(@required_packages)
      if !Package.InstalledAny(
          ["apache2-prefork", "apache2-metuxmpm", "apache2-worker"]
        )
        # add a default MPM - prefork because of the PHP4 compatibility
        required = Convert.convert(
          Builtins.union(required, ["apache2-prefork"]),
          :from => "list",
          :to   => "list <string>"
        )
      end

      if !Package.InstallAllMsg(
          required,
          # notification about package needed 1/2
          _(
            "<p>To configure the HTTP server, the <b>%1</b> packages must be installed.</p>"
          ) +
            # notification about package needed 2/2
            _("<p>Do you want to install it now?</p>")
        )
        if !Package.Available("apache2")
          # translators: error popup before aborting the module
          Popup.Error(
            Builtins.sformat(
              _(
                "The package %1 is not available.\n" +
                  "\n" +
                  "Configuration cannot continue\n" +
                  "\n" +
                  "without installing the package."
              ),
              "apache2"
            )
          )
        else
          # translators: error popup before aborting the module
          Popup.Error(Message.CannotContinueWithoutPackagesInstalled)
        end

        return false
      end



      Progress.NextStep


      # check httpd.conf
      if SCR.Read(path(".target.lstat"), "/etc/apache2/httpd.conf") == {}
        # translators: error message, %1 is the file name of expected configuration file
        Report.Error(
          Builtins.sformat(
            _("The configuration file '%1' does not exist."),
            "/etc/apache2/httpd.conf"
          )
        )
        return false
      end

      # check sysconfig
      if SCR.Read(path(".target.lstat"), "/etc/sysconfig/apache2") == {}
        if SCR.Execute(
            path(".target.bash"),
            "cp /var/adm/fillup-templates/sysconfig.apache2 /etc/sysconfig/apache2"
          ) != 0
          # translators:: error message
          Report.Error(Message.CannotWriteSettingsTo("/etc/sysconfig/apache2"))
          return false
        end
      end

      # check listen.conf
      if SCR.Read(path(".target.lstat"), "/etc/apache2/listen.conf") == {}
        # translators: warning message, %1 is the file name of expected configuration file
        Report.Warning(
          Builtins.sformat(
            _("The configuration file '%1' does not exist."),
            "/etc/apache2/listen.conf"
          )
        )
        # create empty file
        if !SCR.Write(path(".target.string"), "/etc/apache2/listen.conf", "")
          # translators:: error message
          Report.Error(
            Message.CannotWriteSettingsTo("/etc/apache2/listen.conf")
          )
          return false
        end
      end

      old_progress = Progress.set(false) #off();
      SuSEFirewall.Read
      if Package.Installed("bind")
        if Ops.greater_than(
            Builtins.size(
              Convert.to_map(
                SCR.Read(
                  path(".target.stat"),
                  Ops.add(Directory.vardir, "/dns_server")
                )
              )
            ),
            0
          )
          if Service.Status("named") == 0
            @configured_dns = true if DnsServerAPI.Read
          else
            Builtins.y2milestone(
              _("There is no DNS server running on this machine.")
            )
          end
        else
          Builtins.y2warning("DNS server is not correctly configured via YaST.")
        end
      else
        Builtins.y2warning("Package bind is not installed.")
      end
      Builtins.y2internal("DNS running and configured: %1", @configured_dns)
      Progress.set(old_progress) #on();

      # read current settings from httpd.conf and sysconfig
      Progress.NextStage

      # read hosts
      YaST::HTTPDData.ReadHosts
      YaST::HTTPDData.ReadListen
      YaST::HTTPDData.ReadModules
      YaST::HTTPDData.ReadService

      if !FileChanges.CheckFiles(@files_to_check + dynamic_files_to_check())
        return false
      end

      if !FileChanges.CheckNewCreatedFiles(dynamic_files_to_check())
        return false
      end

      # check the modules RPMs
      modules = YaST::HTTPDData.GetModuleList
      Builtins.y2milestone("Testing packages for %1", modules)

      Builtins.foreach(modules) do |mod|
        pkgs = YaST::HTTPDData.GetPackagesForModule(mod)
        if Ops.greater_than(Builtins.size(pkgs), 0)
          Yast.import "Package"
          Builtins.y2milestone("Checking packages %1 for module %2", pkgs, mod)

          res = Builtins.find(pkgs) { |pkg| !Package.Installed(pkg) }

          if res != nil
            Builtins.y2milestone(
              "Packages not installed (missing %1), setting %2 as disabled",
              res,
              mod
            )
            YaST::HTTPDData.ModifyModuleList([mod], false)
          end
        end
      end

      Progress.NextStage

      # read current settings for firewall and network
      old_progress = Progress.set(false) #off();
      NetworkInterfaces.Read

      # generate the map: static IP -> device
      @ip2device = { "127.0.0.1" => "loopback" }
      devs = NetworkInterfaces.Locate("BOOTPROTO", "static")
      Builtins.foreach(devs) do |dev|
        # use also additional addresses (#264393)
        Builtins.foreach(NetworkInterfaces.GetIP(dev)) do |ip|
          Ops.set(@ip2device, ip, dev) if ip != nil && ip != ""
        end
      end
      # add DHCP ones, if we can find out the current IP
      devs = NetworkInterfaces.Locate("BOOTPROTO", "dhcp")
      Builtins.foreach(devs) do |dev|
        output = Convert.to_map(
          SCR.Execute(
            path(".target.bash_output"),
            Ops.add("/sbin/ifconfig ", dev),
            { "LC_MESSAGES" => "C" }
          )
        )
        if Ops.get_integer(output, "exit", -1) == 0
          # lookup the correct line first
          line = Builtins.splitstring(
            Ops.get_string(output, "stdout", ""),
            "\n"
          )
          addr = nil
          Builtins.foreach(line) do |ln|
            if Builtins.regexpmatch(ln, "^[ \t]*inet addr:")
              addr = Builtins.regexpsub(
                ln,
                "^[ \t]*inet addr:([0-9\\.]+)[ \t]*",
                "\\1"
              )
              Builtins.y2milestone("Found addr: %1", addr)
              raise Break
            end
          end

          Ops.set(@ip2device, addr, dev) if addr != nil && addr != ""
        end
      end

      Builtins.y2milestone(
        "Mapping of IP addresses and network devices: %1",
        @ip2device
      )


      Progress.set(old_progress) #on();

      # translators: progress step
      ProgressNextStage(_("Finished"))

      return false if Abort()
      @modified = false

      @configured = true

      true
    end

    # Write all http-server settings
    # @return true on success
    def Write
      # HttpServer read dialog caption
      caption = _("Saving HTTP Server Configuration")

      steps = 3

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # translators: progress stage 1/3
          _("Write the Apache2 settings"),
          YaST::HTTPDData.GetService ?
            # translators: progress stage 2/3
            _("Enable Apache2 service") :
            # translators: progress stage 3/3
            _("Disable Apache2 service")
        ],
        [
          # translators: progress step 1/3
          _("Writing the settings..."),
          YaST::HTTPDData.GetService ?
            # translators: progress step 2/3
            _("Enabling Apache2 service...") :
            # translators: progress step 3/3
            _("Disabling Apache2 service..."),
          # translators: progress finished
          _("Finished")
        ],
        ""
      )

      # write Apache2 settings

      rpms = YaPI::HTTPD.GetModulePackages

      # install required RPMs for modules
      Package.InstallAllMsg(
        rpms,
        _(
          "The enabled modules require\n" +
            "installation of some of these additional packages:\n" +
            "%1\n" +
            "Install them now?\n"
        )
      )

      # write httpd.conf

      # write hosts
      YaST::HTTPDData.WriteHosts
      Progress.NextStage
      Yast.import "SuSEFirewall"
      old_progress = Progress.set(false) # off();

      # always adapt firewall
      if YaST::HTTPDData.WriteListen(false) == nil
        # FIXME: show popup

        Builtins.y2error("Writing listen failed, firewall problems?")
      end

      # Firewall
      ports = []
      Builtins.foreach(YaST::HTTPDData.GetCurrentListen) do |row|
        ports = Builtins.add(ports, Ops.get_string(row, "PORT", ""))
      end
      SuSEFirewallServices.SetNeededPortsAndProtocols(
        "service:apache2",
        { "tcp_ports" => ports, "udp_ports" => [] }
      )

      SuSEFirewall.Write
      DnsServerAPI.Write if @configured_dns
      Progress.set(old_progress)
      YaST::HTTPDData.WriteModuleList
      # in autoyast, quit here
      # Wrong, service still has to be enabled...
      # if( write_only ) return true;


      Progress.NextStage

      if !YaST::HTTPDData.WriteService(@write_only)
        # translators: error message
        Report.Error(Message.CannotAdjustService("apache2"))
      end

      if YaST::HTTPDData.GetService
        # this will reload the configuration and start httpd
        if !Service.Restart("apache2")
          # translators: error message
          Report.Error(Message.CannotAdjustService("apache2"))
        end
      else
        if !Service.Stop("apache2")
          # translators: error message
          Report.Error(Message.CannotAdjustService("apache2"))
        end
      end
      # configuration test
      #	map<string, any> test = (map<string, any>)SCR::Execute(.target.bash_output, "apache2ctl conftest");
      #y2internal("test %1", test);

      (@files_to_check + dynamic_files_to_check()).each do |file|
        FileChanges.StoreFileCheckSum(file)
      end
      # translators: progress finished
      ProgressNextStage(_("Finished"))

      return false if Abort()
      true
    end


    # For module name find description map in known_modules
    # @param [Array<Hash{String => Object>}] known_modules list< map<string,any> > known modules
    # @param [String] mod string module name
    # @return [Hash{String => Object}] module description
    def find_known_module(known_modules, mod)
      known_modules = deep_copy(known_modules)
      res = nil
      Builtins.foreach(known_modules) do |i|
        if Ops.get_string(i, "name", "") == mod
          res = deep_copy(i)
          raise Break
        end
      end

      deep_copy(res)
    end

    # Get all http-server settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] s The YCP map to be imported
    # @return [Boolean] True on success
    def Import(s)
      s = deep_copy(s)
      YaST::HTTPDData.InitializeDefaults

      version = Ops.get_string(s, "version", "unknown")

      # setup modules
      Builtins.foreach(Ops.get_list(s, "modules", [])) do |desc|
        mod = Ops.get_string(desc, "name", "")
        if Builtins.size(mod) == 0
          # translators: warning in autoyast loading the configuration description.
          Report.Warning(
            _("Module description does not have a name specified, ignoring.")
          )
          next
        end
        change_string = Ops.get_string(desc, "change", "nochange")
        # get the default
        defaultstatus = Ops.get_string(desc, "default")
        if change_string != "nochange"
          if !Builtins.contains(["enable", "disable"], change_string)
            # translators: warning in autoyast loading the configuration description.
            Report.Warning(
              Builtins.sformat(
                _("Unknown change of a module for autoinstallation: %1"),
                change_string
              )
            )
            next
          end

          # just change the status
          YaST::HTTPDData.ModifyModuleList([mod], change_string == "enable")
        else
          # check against the current default
          if defaultstatus != nil &&
              Ops.get(
                find_known_module(YaST::HTTPDData.GetKnownModules, mod),
                "default"
              ) != defaultstatus
            # translators: warning in autoyast loading the configuration description.
            Report.Warning(
              Builtins.sformat(
                _(
                  "Default value for module %1 does not match.\nThis can cause inconsistent module configuration."
                ),
                mod
              )
            )
          end
        end
      end

      # setup listen
      listen = Ops.get_list(s, "Listen", [])
      Builtins.foreach(listen) do |l|
        if !Builtins.haskey(l, "PORT")
          # translators: error in autoyast loading the configuration description.
          Report.Error(_("Listen statement without port found."))
        else
          YaST::HTTPDData.CreateListen(
            Builtins.tointeger(Ops.get_string(l, "PORT", "0")),
            Builtins.tointeger(Ops.get_string(l, "PORT", "0")),
            Ops.get_string(l, "ADDRESS", "")
          )
        end
      end

      # setup hosts
      default_server = nil
      Builtins.foreach(Ops.get_list(s, "hosts", [])) do |row|
        # "main" defines the default server configured in
        # /etc/apache2/default-server.conf. This has already been
        # defined in YaPI::HTTPD and has to be updated only.
        # With the CreateHost call an own entry in /etc/apache2/vhosts.d
        # will be generated.
        # (bnc#893100)
        if row["KEY"] == "main"
          default_server = row
        else
          value = row["VALUE"] || []
          key_split = row["KEY"].split("/")
          if value.none? {|item| item["KEY"] == "HostIP"} && key_split.size > 1
            # Set HostIP which is given in the KEY (e.g. *:443/sleposbuilder3.suse.cz.conf)
            # values in order to set VirtualHost in /etc/apache2/vhosts.d/<hostname>
            # (bnc#895127)
            host_ip = key_split.first
            value << {"KEY" => "HostIP", "VALUE" => host_ip}
          end
          YaST::HTTPDData.CreateHost(
            row["KEY"] || "",
            value
          )
        end
      end

      # Every YaST::HTTPDData.CreateHost resets the NameVirtualHost
      # entry in default-server.conf. I do not really know the
      # reason for, but in that case it is not intent (schubi).
      # So, the default server will be modified AFTER all other
      # hosts have been created to get the correct NameVirtualHost entry
      if default_server
        YaST::HTTPDData.ModifyHost(
          default_server["KEY"],
          default_server["VALUE"] || []
        )
      end

      # setup service
      if Builtins.haskey(s, "service")
        YaST::HTTPDData.ModifyService(Ops.get_boolean(s, "service", false))
      end

      @modified = false
      @configured = true

      true
    end

    # Dump the http-server settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      known_modules = YaST::HTTPDData.GetKnownModules

      enabled_modules = YaST::HTTPDData.GetModuleList

      Builtins.y2milestone("Enabled modules: %1", enabled_modules)

      # walk over the known modules
      modules = Builtins.maplist(known_modules) do |desc|
        {
          "name"    => Ops.get_string(desc, "name", ""),
          "change"  => Ops.get(desc, "default") == "1" ?
            # default is true
            Builtins.contains(enabled_modules, Ops.get_string(desc, "name", "")) ? "nochange" : "disable" :
            # default is false
            Builtins.contains(enabled_modules, Ops.get_string(desc, "name", "")) ? "enable" : "nochange",
          "default" => Ops.get_string(desc, "default", "1")
        }
      end

      # filter out not changed
      modules = Builtins.filter(modules) do |desc|
        Ops.get(desc, "change") != "nochange"
      end

      # store the user defined ones
      Builtins.foreach(enabled_modules) do |mod|
        if find_known_module(known_modules, mod) == nil
          # user-defined
          modules = Builtins.add(
            modules,
            { "name" => mod, "change" => "enable", "userdefined" => true }
          )
        end
      end

      # hosts
      hosts = []
      #listmap (string host, YaST::HTTPDData::GetHostsList(), ``(
      #	$[ "KEY":host, "VALUE":YaST::HTTPDData::GetHost(host) ]
      #    ));
      Builtins.foreach(YaST::HTTPDData.GetHostsList) do |host|
        hosts = Builtins.add(
          hosts,
          { "KEY" => host, "VALUE" => YaST::HTTPDData.GetHost(host) }
        )
      end

      Builtins.y2milestone("Hosts: %1", hosts)

      result = {
        "version" => "2.9",
        "modules" => modules,
        "hosts"   => hosts,
        "Listen"  => YaST::HTTPDData.GetCurrentListen,
        "service" => YaST::HTTPDData.GetService
      }

      @configured = true
      deep_copy(result)
    end

    # Create a textual summary for the current configuration
    # @return summary of the current configuration
    def Summary
      nc = Summary.NotConfigured

      summary = ""
      if @configured
        # "Listen on " information (interfaces, port)
        summary = Summary.AddLine(summary, _("<h3>Listen On</h3>"))
        port = "80"
        interfaces = "127.0.0.1"
        Builtins.foreach(YaST::HTTPDData.GetCurrentListen) do |listens|
          port = Ops.get_string(listens, "PORT", "80")
          if Ops.get_string(listens, "ADDRESS", "") == ""
            interfaces = "all"
          else
            interfaces = Ops.add(
              interfaces,
              Ops.get_string(listens, "ADDRESS", "")
            )
          end
        end
        summary = Summary.AddLine(
          summary,
          Ops.add(Ops.add(interfaces, ", port "), port)
        )

        # "Default host" information
        summary = Summary.AddLine(summary, _("<h3>Default Host</h3>"))
        serv_name = ""
        doc_root = ""
        ssl = false
        Builtins.foreach(YaST::HTTPDData.GetHost("default")) do |params|
          if Ops.get_string(params, "KEY", "") == "ServerName"
            serv_name = Ops.get_string(params, "VALUE", "")
          end
          if Ops.get_string(params, "KEY", "") == "DocumentRoot"
            doc_root = Ops.get_string(params, "VALUE", "")
          end
          if Ops.get_string(params, "KEY", "") == "SSL" &&
              Ops.get_string(params, "VALUE", "") != "0"
            ssl = true
          end
        end
        #translators: assiciation server name with document root
        summary = Summary.AddLine(
          summary,
          Ops.add(Ops.add(serv_name, _(" in ")), doc_root)
        )
        #translators: whether SSL is enabled or disabled
        summary = Summary.AddLine(
          summary,
          "SSL " + (ssl ? _("enabled") : _("disabled"))
        )

        # the same information as in default host but for other virtual hosts
        summary = Summary.AddLine(summary, _("<h3>Virtual Hosts</h3>"))

        Builtins.foreach(YaST::HTTPDData.GetHostsList) do |host|
          next if host == "default"
          Builtins.foreach(YaST::HTTPDData.GetHost(host)) do |params|
            if Ops.get_string(params, "KEY", "") == "ServerName"
              serv_name = Ops.get_string(params, "VALUE", "")
            end
            if Ops.get_string(params, "KEY", "") == "DocumentRoot"
              doc_root = Ops.get_string(params, "VALUE", "")
            end
            if Ops.get_string(params, "KEY", "") == "SSL" &&
                Ops.get_string(params, "VALUE", "") != "0"
              ssl = true
            end
          end
          #translators: assiciation server name with document root
          summary = Summary.AddLine(
            summary,
            Ops.add(
              Ops.add(
                Ops.add(Ops.add(serv_name, _(" in ")), doc_root),
                #translators: whether SSL is enabled or disable
                ", SSL "
              ),
              ssl ? _("enabled") : _("disabled")
            )
          )
        end
      else
        summary = Summary.AddLine(summary, nc)
      end

      [summary, []]
    end

    # Return required packages for auto-installation
    # @return [Hash] of packages to be installed and to be removed
    def AutoPackages
      if !Package.InstalledAny(
          ["apache2-prefork", "apache2-metuxmpm", "apache2-worker"]
        )
        # add a default MPM - prefork because of the PHP4 compatibility
        @required_packages = Convert.convert(
          Builtins.union(@required_packages, ["apache2-prefork"]),
          :from => "list",
          :to   => "list <string>"
        )
      end

      { "install" => @required_packages, "remove" => [] }
    end

    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :variable => :required_packages, :type => "list <string>"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :configured, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :configured_dns, :type => "boolean"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :PollAbort, :type => "boolean ()"
    publish :function => :ReallyAbort, :type => "boolean ()"
    publish :function => :ProgressNextStage, :type => "void (string)"
    publish :function => :listen2item, :type => "term (string, integer)"
    publish :function => :listen2map, :type => "map (string)"
    publish :variable => :ip2device, :type => "map <string, string>"
    publish :function => :isWizardMode, :type => "boolean ()"
    publish :function => :setWizardMode, :type => "void (boolean)"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
  end

  HttpServer = HttpServerClass.new
  HttpServer.main
end
