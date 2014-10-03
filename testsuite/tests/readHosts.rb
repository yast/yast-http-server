# encoding: utf-8

#testfiles: YaST::HTTPDData.pm
#return all hosts parameters
#return  list of hosts
#return parameters of given host
module Yast
  class ReadHostsClient < Client
    def main
      Yast.include self, "testsuite.rb"

      @READ = {
        "http_server" => {
          "vhosts" => {
            "default-server.conf" => [
              {
                "DATA"          => [
                  {
                    "KEY"      => "DocumentRoot",
                    "OVERHEAD" => "",
                    "VALUE"    => "\"/srv/www/htdocs\""
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "Directory",
                    "SECTIONPARAM" => "\"/srv/www/htdocs\"",
                    "VALUE"        => [
                      {
                        "KEY"      => "Options",
                        "OVERHEAD" => "",
                        "VALUE"    => "None"
                      },
                      {
                        "KEY"      => "AllowOverride",
                        "OVERHEAD" => "",
                        "VALUE"    => "None"
                      },
                      { "KEY" => "Require", "VALUE" => "all granted" }
                    ]
                  },
                  {
                    "KEY"      => "Alias",
                    "OVERHEAD" => "",
                    "VALUE"    => "/icons/ \"/usr/share/apache2/icons/\""
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "Directory",
                    "SECTIONPARAM" => "\"/usr/share/apache2/icons\"",
                    "VALUE"        => [
                      { "KEY" => "Options", "VALUE" => "Indexes MultiViews" },
                      { "KEY" => "AllowOverride", "VALUE" => "None" },
                      { "KEY" => "Require", "VALUE" => "all granted" }
                    ]
                  },
                  {
                    "KEY"      => "ScriptAlias",
                    "OVERHEAD" => "",
                    "VALUE"    => "/cgi-bin/ \"/srv/www/cgi-bin/\""
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "Directory",
                    "SECTIONPARAM" => "\"/srv/www/cgi-bin\"",
                    "VALUE"        => [
                      { "KEY" => "AllowOverride", "VALUE" => "None" },
                      { "KEY" => "Options", "VALUE" => "+ExecCGI -Includes" },
                      { "KEY" => "Require", "VALUE" => "all granted" }
                    ]
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "IfModule",
                    "SECTIONPARAM" => "mod_userdir.c",
                    "VALUE"        => [
                      {
                        "KEY"      => "UserDir",
                        "OVERHEAD" => "",
                        "VALUE"    => "public_html"
                      },
                      {
                        "KEY"      => "Include",
                        "OVERHEAD" => "",
                        "VALUE"    => "/etc/apache2/mod_userdir.conf"
                      }
                    ]
                  },
                  {
                    "KEY"      => "Include",
                    "OVERHEAD" => "",
                    "VALUE"    => "/etc/apache2/conf.d/*.conf"
                  },
                  {
                    "KEY"      => "Include",
                    "OVERHEAD" => "",
                    "VALUE"    => "/etc/apache2/conf.d/apache2-manual?conf"
                  },
                  { "KEY" => "ServerName", "VALUE" => "test" },
                  { "KEY" => "ServerAdmin", "VALUE" => "test@test" },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "Directory",
                    "SECTIONPARAM" => "\"/srv/viewcvs/\"",
                    "VALUE"        => [
                      { "KEY" => "Options", "VALUE" => "None" },
                      { "KEY" => "AllowOverride", "VALUE" => "None" },
                      { "KEY" => "Require", "VALUE" => "all granted" }
                    ]
                  },
                  { "KEY" => "NameVirtualHost", "VALUE" => "10.20.1.28" },
                  {
                    "KEY"          => "_SECTION",
                    "SECTIONNAME"  => "IfDefine",
                    "SECTIONPARAM" => "SSL",
                    "VALUE"        => [
                      { "KEY" => "SSLEngine", "VALUE" => "off" }
                    ]
                  }
                ],
                "HOSTID"        => "default",
                "VirtualByName" => "0"
              }
            ],
            "yast2_vhosts.conf"   => [
              {
                "DATA"          => [
                  { "KEY" => "DocumentRoot", "VALUE" => "/srv/viewcvs/" },
                  { "KEY" => "ServerName", "VALUE" => "TestNew" },
                  { "KEY" => "ServerAdmin", "VALUE" => "ja@ja.sk" },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "IfDefine",
                    "SECTIONPARAM" => "SSL",
                    "VALUE"        => [
                      { "KEY" => "SSLRequireSSL", "VALUE" => "" }
                    ]
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "IfDefine",
                    "SECTIONPARAM" => "SSL",
                    "VALUE"        => [
                      { "KEY" => "SSLRequireSSL", "VALUE" => "" }
                    ]
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "IfDefine",
                    "SECTIONPARAM" => "SSL",
                    "VALUE"        => [
                      { "KEY" => "SSLRequireSSL", "VALUE" => "" }
                    ]
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "IfDefine",
                    "SECTIONPARAM" => "SSL",
                    "VALUE"        => [
                      { "KEY" => "SSLEngine", "VALUE" => "on" }
                    ]
                  },
                  {
                    "KEY"          => "_SECTION",
                    "OVERHEAD"     => "",
                    "SECTIONNAME"  => "IfDefine",
                    "SECTIONPARAM" => "SSL",
                    "VALUE"        => [
                      { "KEY" => "SSLRequireSSL", "VALUE" => "" }
                    ]
                  }
                ],
                "HOSTID"        => "10.20.1.28/TestNew",
                "HostIP"        => "10.20.1.28",
                "VirtualByName" => "1"
              },
              { "OVERHEAD" => "" }
            ]
          }
        }
      }

      TESTSUITE_INIT([@READ, {}, {}], nil)

      Yast.import "YaST::HTTPDData"
      Yast.import "YaPI::HTTPD"


      TEST(lambda { YaST::HTTPDData.ReadHosts }, [@READ, {}, {}], nil)
      TEST(lambda { YaST::HTTPDData.GetHostsList }, [@READ, {}, {}], nil)
      TEST(lambda { YaST::HTTPDData.GetHost("10.20.1.28/TestNew") }, [
        @READ,
        {},
        {}
      ], nil)
      TEST(lambda { YaST::HTTPDData.GetHost("default") }, [@READ, {}, {}], nil)

      nil
    end
  end
end

Yast::ReadHostsClient.new.main
