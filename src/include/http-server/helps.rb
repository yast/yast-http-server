# encoding: utf-8

# File:	include/http-server/helps.ycp
# Package:	Configuration of http-server
# Summary:	Help texts of all the dialogs
# Authors:	Jiri Srain <jsrain@suse.cz>
#		Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
module Yast
  module HttpServerHelpsInclude
    def initialize_http_server_helps(include_target)
      textdomain "http-server"
      Yast.import "ProductFeatures"
      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"              => _(
          "<p><b><big>Initializing HTTP Server Configuration</big></b>\n" +
            "<br>\n" +
            "Please wait...<br></p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"             => _(
          "<p><b><big>Saving HTTP Server Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog informs you whether it is safe to do so.</p>\n"
          ),
        #translators: Wizard dialog 1/5
        "open_port"         => _(
          "<p>The <b>Port</b> value defines the port on which Apache2 listens. The default is 80.</p>"
        ),
        #translators: Wizard dialog 1/5
        "listen_interfaces" => _(
          "<p><b>Listen on Interfaces</b> contains the list of all IP addresses configured for this host. Checked IP addresses are those on which Apache2 listens. If you are unsure, check all.</p>"
        ),
        #translators: Wizard dialog 2/5
        "script_modules"    => _(
          "<p>Here, enable the script languages the Apache2 server should support.</p>"
        ),
        #translators: Wizard dialog 5/5
        "summary_text"      => _(
          "<p>The summary displays the settings that will be written to the Apache2 configuration when you press <b>Finish</b>.</p>"
        ),
        #translators: Wizard dialog 5/5
        "expert_conf"       => _(
          "<p>Press <b>HTTP Server Expert Configuration</b> \n\t\tto create a more detailed configuration before writing the configuration.</p>"
        ),
        # module dialog help 1/3
        "modules"           => _(
          "<p><b><big>Editing HTTP Server Modules</big></b><br>\n" +
            "The table contains a list of all available Apache2 modules.\n" +
            "The first column contains the name of the module. \n" +
            "The second column shows whether the module should be\n" +
            "loaded by the server. Enabled modules will be loaded. The last column displays a short description\n" +
            "of the module.</p>"
        ) +
          # module dialog help 2/3
          _(
            "<p>To change the status of a module, \nchoose the appropriate entry of the table and click <b>Toggle Status</b>.</p>\n"
          ) +
          # module dialog help 3/3
          _(
            "<p>If you need to add a module not listed in the table, \nuse <b>Add Module</b>.</p>\n"
          ),
        # apache service enabling help 1/1
        "server_enable"     => _(
          "<p><b><big>HTTP Server Settings</big></b><br>\n" +
            "Activate the HTTP server by choosing <b>Enabled</b>. To deactivate it, choose\n" +
            "<b>Disabled</b>.</p>\n"
        ),
        # firewall adapting help 1/1
        "firewall_adapt"    => _(
          "<p>By enabling <b>Open Firewall on Selected Ports</b>, \n" +
            "adapt the firewall according the ports on which Apache2 listens. \n" +
            "The interfaces of the firewall are not added or deleted. \n" +
            "This option is only available if the firewall is enabled.</p>\n"
        ),
        # server configuration overview help 1/2
        "overview_widget"   => _(
          "<p>The list of options presents\n" +
            "several parts of the server configuration. <b>Listen On</b>\n" +
            "contains a list of ports and IP addresses on which the\n" +
            "server should listen for the incoming requests. \n" +
            "<b>Modules</b> allows configuring the modules loaded by the\n" +
            "server.\n" +
            "<b>Default Host</b> is a server name of a host used as a\n" +
            "default (fallback) host. If the server name of the default\n" +
            "host is not specified, a path to the document root of the\n" +
            "default host is displayed.\n" +
            "<b>Hosts</b> contains a list of hosts configured for the server.</p>\n"
        ) +
          # server configuration overview help 2/2
          _(
            "<p>Choose an appropriate entry from the table and click <b>Edit</b> to change settings.</p>"
          ) +
          # help of menu button for server configuration 1/1
          _("<p><b>Log Files</b> displays server log files.</p>"),
        # hosts list help 1/2
        "hosts"             => _(
          "<p><b><big>Configured Hosts</big></b><br>\n" +
            "This is a list of already configured hosts. One of the hosts is \n" +
            "marked as default (the asterisk next to the server name). A default host is used if no other host\n" +
            "matches for an incoming request. To set a host as default,\n" +
            "press <b>Set as Default</b>.</p>\n"
        ) +
          # hosts list help 2/2
          _(
            "<p>Choose an appropriate entry of the table and click <b>Edit</b> to change the host.\nTo add a host, click <b>Add</b>. To remove a host, select it and click <b>Delete</b>.</p>"
          ),
        # host editing help 1/2
        "global_table"      => _(
          "<p><b><big>Host Configuration</big></b><br>\n" +
            "To edit the host settings, choose the appropriate entry of the table then click <b>Edit</b>.\n" +
            "To add a new option, click <b>Add</b>. To remove an option, select it and click <b>Delete</b>.</p>"
        ) +
          # host editing help 2/2
          _(
            "<p>The <b>Server Resolution</b> options set the resolution when using\n" +
              "\tvirtual hosts. However, when you choose <b>Resolution via HTTP Headers</b>,\n" +
              "\tthe default server will never be served requests to the IP address of\n" +
              "\ta name-based virtual host. If you plan to configure a SSL based vhost, use <b>Resolution via IP address</b></p>"
          ),
        # listen dialog editor help 1/2
        "listen"            => _(
          "<p><b><big><i>Listen</i> Settings for a Host</big></b><br>\n" +
            "The <i>Listen</i> directive allows selection of ports and network interfaces\n" +
            "where the HTTP server should listen for incoming requests.</p>\n"
        ) +
          # listen dialog editor help 2/2
          _(
            "<p>Choose an appropriate entry of the table and click <b>Edit</b> to change the entry.\nTo add a new entry, click <b>Add</b>. To remove an entry, select it and click <b>Delete</b>.</p>"
          ),
        # ssl options dialog help 1/4
        "ssl"               => _(
          "<p><b><big>SSL Configuration</big></b><br>\n" +
            "This is a list of options related to the SSL (Secure Socket Layer) settings\n" +
            "of the host. SSL allows communicating securely with the host by \n" +
            "encrypting communication.</p>\n"
        ) +
          # ssl options dialog help 2/4
          _(
            "<p>General behavior is determined by the SSL option. The host can\n" +
              "not support SSL at all (<tt>No SSL</tt>), allow both non-SSL and SSL access (<tt>Allowed</tt>),\n" +
              "or accept only connections encrypted via SSL (<tt>Required</tt>).\n" +
              "</p>\n"
          ) +
          # ssl options dialog help 3/4
          _(
            "<p>Choose an appropriate option of the table and click <b>Edit</b> to change the option.\nTo add a new option, click <b>Add</b>. To remove an option, select it and click <b>Delete</b>.</p>"
          ) +
          # ssl options dialog help 3/4 (empty in simple mode)
          (ProductFeatures.GetFeature("globals", "ui_mode") != "simple" ?
            _(
              "<p>The <b>Certificates</b> menu allows \n" +
                "importing server certificates. <b>Import Server Certificate</b> \n" +
                "allows use of a special purpose certificate. \n" +
                "<b>Use Common Certificate</b> configures usage of the\n" +
                "common certificate issued for this host.</p>\n"
            ) :
            "") +
          # ssl options dialog help 4/4
          _(
            "<p><b>Note:</b> If you enable use of SSL for a host, the <tt>mod_ssl</tt> \nmodule should be loaded by the server.</p>\n"
          ),
        # new host dialog help 1/3
        "add_host_general"  => _(
          "<p><b><big>New Host</big></b><br>\nThis dialog allows you to enter a basic information about a new virtual host.</p>"
        ) +
          # new host dialog help 2/3
          _(
            "<p><b>Server Identification</b> specifies the content and\n" +
              "the presentation of the the new virtual host. <b>Server Name</b> is the DNS name returned as a part\n" +
              "of the HTTP headers of the server response. <b>Server Contents Root</b>\n" +
              "is an absolute path to a directory containing all documents provided by\n" +
              "this virtual host. <b>Administrator E-Mail</b> allows setup of an e-mail\n" +
              "address for feedback about this host.</p>\n"
          ) +
          # new host dialog help 3/3
          _(
            "<p><big><b>Server Resolution</b></big><br>\n" +
              "Apache2 must be able to determine which virtual host\n" +
              "settings it should use to create a response for an HTTP request. \n" +
              "There are two basic approaches. If using HTTP headers\n" +
              "from the incoming request, the server looks up the host name specified by\n" +
              "the HTTP request headers. The other possibility is to determine the virtual host\n" +
              "by the IP address used by the client when connecting to the server.\n" +
              "If you plan to configure SSL-based vhost, use <b>Resolution via IP address</b>\n" +
              "Consult the Apache2 manual for further details.</p>\n"
          ),
        # advanced new host dialog 1/5
        "set_vhost"         => _(
          "<p><b><big>Details for New Host</big></b><br>\nThis dialog allows you to specify additional information about a new virtual host.</p>"
        ) +
          # advanced new host dialog 2/5
          _(
            "<p>Select <b>Enable CGI Support</b>\nto run CGI scripts in the path in <b>CGI Directory Path</b> using the alias <tt>/cgi-bin/</tt>.</p>"
          ) +
          # advanced new host dialog 3/5
          _(
            "<p>For HTTPS access to this virtual host, select <b>Enable SSL Support</b>.\n" +
              "\n" +
              "Then enter the path for the certificate file in <b>Certificate File\n" +
              "Path</b>.This option is only available for IP-based vhosts.</p>\n"
          ) +
          # advanced new host dialog 4/5
          _(
            "<p>In <b>Directory Index</b>, enter a space-separated list of files that Apache should look for and provide when a URL for a directory (one that ends in <tt>/</tt>) is requested.  The first matching file found is provided.</p>"
          ) +
          # advanced new host dialog 5/5
          _(
            "<p><b>Public HTML</b>\n" +
              "\n" +
              "enables access to <tt>.public_html</tt> directories of all users.</p>"
          )
      } 

      # EOF
    end
  end
end
