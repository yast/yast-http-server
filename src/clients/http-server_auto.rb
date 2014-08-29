# encoding: utf-8

# File:	clients/http-server_auto.ycp
# Package:	Configuration of http-server
# Summary:	Client for autoinstallation
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of http-server settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("http-server_auto", [ "Summary", mm ]);
module Yast
  class HttpServerAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "http-server"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("HttpServer auto started")

      Yast.import "HttpServer"
      Yast.include self, "http-server/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      if @func == "Summary"
        @ret = Ops.get_string(HttpServer.Summary, 0, "")
      # Reset configuration
      elsif @func == "Reset"
        HttpServer.Import({})
        HttpServer.configured = false
        @ret = {}
      # Change configuration (run AutoSequence)
      elsif @func == "Change"
        @ret = HttpServerAutoSequence()
      # Import configuration
      elsif @func == "Import"
        HttpServer.configured = false
        @ret = HttpServer.Import(@param)
      # Return required packages
      elsif @func == "Packages"
        @ret = HttpServer.AutoPackages
      elsif @func == "GetModified"
        @ret = HttpServer.modified
      elsif @func == "SetModified"
        HttpServer.modified = true
        HttpServer.configured = true
        @ret = true
      # Return actual state
      elsif @func == "Export"
        @ret = HttpServer.Export
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        old_progress = Progress.set(false) #off();
        Progress.off
        @ret = HttpServer.Read
        Progress.set(old_progress)
      # Write givven settings
      elsif @func == "Write"
        Yast.import "Progress"
        old_progress = Progress.set(false) #off();
        HttpServer.write_only = true
        @ret = HttpServer.Write
        Progress.set(old_progress)
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("HttpServer auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::HttpServerAutoClient.new.main
