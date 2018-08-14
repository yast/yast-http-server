# encoding: utf-8

#testedfile: YaST::HTTPDData.pm
#return list of maps directory parameters
module Yast
  class ParseDirOptionClient < Client
    def main
      Yast.include self, "testsuite.rb"

      Yast.import "YaPI::HTTPD"
      Yast.import "YaST::HTTPDData"

      TEST(lambda do
        YaST::HTTPDData.ParseDirOption(
          "/usr/share/YaST2/modules/\nYaST2/modules\n"
        )
      end, [
        {},
        {},
        {}
      ], nil)

      nil
    end
  end
end

Yast::ParseDirOptionClient.new.main
