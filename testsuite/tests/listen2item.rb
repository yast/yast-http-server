# encoding: utf-8

#testedfile: routines.ycp
#return list [ item, address, port ]
module Yast
  class Listen2itemClient < Client
    def main
      Yast.import "UI"
      Yast.include self, "testsuite.rb"


      Yast.include self, "http-server/routines.rb"

      TEST(lambda { listen2item("192.168.1.2:80", 0) }, [{}, {}, {}], nil)

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

Yast::Listen2itemClient.new.main
