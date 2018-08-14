# encoding: utf-8

#testfile: YaST::HTTPDData.pm
#return list of current listens
module Yast
  class ReadListenClient < Client
    def main
      Yast.include self, "testsuite.rb"

      @READ = { "http_server" => { "listen" => ["80", "127.0.0.1:99"] } }
      TESTSUITE_INIT([@READ, {}, {}], nil)

      Yast.import "YaPI::HTTPD"
      Yast.import "YaST::HTTPDData"

      TEST(lambda { YaST::HTTPDData.ReadListen }, [@READ, {}, {}], nil)

      nil
    end
  end
end

Yast::ReadListenClient.new.main
