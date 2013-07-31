# encoding: utf-8

#testfile: routines.ycp
#return list of maps [ address:"address", port:"port" ]
module Yast
  class Listen2mapClient < Client
    def main
      Yast.import "UI"
      Yast.include self, "testsuite.rb"


      Yast.include self, "http-server/routines.rb"

      TEST(lambda { listen2map("192.168.1.2:80") }, [{}, {}, {}], nil)

      nil
    end

    def Modified
      true
    end

    def AbortFunction
      true
    end
  end
end

Yast::Listen2mapClient.new.main
