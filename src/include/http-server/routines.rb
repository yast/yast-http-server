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
module Yast
  module HttpServerRoutinesInclude
    def initialize_http_server_routines(include_target)
      textdomain "http-server"

      Yast.import "Directory"
      Yast.import "Progress"
      Yast.import "String"
      Yast.import "Popup"
    end

    # Abort function
    # @return blah blah lahjk
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
      false
    end

    # Check for pending Abort press
    # @return true if pending abort
    def PollAbort
      UI.PollInput == :abort
    end

    # If modified, ask for confirmation
    # @return true if abort is confirmed
    def ReallyAbort
      !Modified() || Popup.ReallyAbort(true)
    end

    # Progress::NextStage and Progress::Title combined into one function
    # @param [String] title progressbar title
    def ProgressNextStage(title)
      Progress.NextStage
      Progress.Title(title)

      nil
    end

    # Convert a Listen string to an item for table. Splits by the colon.
    #
    # @param [String] arg		the Listen string
    # @param [Fixnum] id		the id of this item
    # @return [Yast::Term]		term for the table
    def listen2item(arg, id)
      colon = Builtins.search(arg, ":")

      address = _("All Addresses")
      port = arg

      if colon != nil
        # address is present
        address = Builtins.substring(arg, 0, colon)
        port = Builtins.substring(arg, Ops.add(colon, 1))
      end
      Item(Id(id), address, port)
    end

    # Convert a Listen string to a pair: $[ "port": port, "address": network ]
    #
    # @param [String] arg		the Listen string
    # @return [Hash]		map with the result
    def listen2map(arg)
      colon = Builtins.search(arg, ":")

      address = "all"
      port = arg

      if colon != nil
        # address is present
        address = Builtins.substring(arg, 0, colon)
        port = Builtins.substring(arg, Ops.add(colon, 1))
      end
      { "port" => port, "address" => address }
    end
  end
end
