# encoding: utf-8

# testedfile: YaST::HTTPDData.pm
# return map of ip addresses and ports where apache2 listens
module Yast
  class GetCurrentListenClient < Client
    def main
      Yast.include self, "testsuite.rb"

      @READ = { "http_server" => { "listen" => ["80", "127.0.0.1:99"] } }
      TESTSUITE_INIT([@READ, {}, {}], nil)

      Yast.import "YaST::HTTPDData"
      Yast.import "YaPI::HTTPD"


      TEST(lambda { YaST::HTTPDData.ReadListen }, [@READ, {}, {}], nil)

      nil
    end
  end
end

Yast::GetCurrentListenClient.new.main
