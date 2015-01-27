# encoding: utf-8

# File:	include/http-server/complex.ycp
# Package:	Configuration of http-server
# Summary:	Dialogs definitions
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
module Yast
  module HttpServerComplexInclude
    def initialize_http_server_complex(include_target)
      textdomain "http-server"

      Yast.import "Wizard"
      Yast.import "HttpServer"
      Yast.import "YaST::HTTPDData"

      Yast.import "Label"
      Yast.import "Popup"

      Yast.include include_target, "http-server/helps.rb"
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      HttpServer.Modified
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      HttpServer.AbortFunction = fun_ref(
        HttpServer.method(:PollAbort),
        "boolean ()"
      )
      ret = HttpServer.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      HttpServer.AbortFunction = fun_ref(
        HttpServer.method(:PollAbort),
        "boolean ()"
      )
      ret = HttpServer.Write
      ret ? :next : :back
    end

    # Abort dialog ask user for abort application
    # @return [Boolean] do abort
    def ReallyAbort
      !HttpServer.modified || Popup.ReallyAbort(true)
    end
  end
end
