#!/usr/bin/env rspec

require_relative "test_helper"
require "yast"

describe "Yast::HttpServerRoutinesInclude" do
  before(:each) do
    # deep in HttpServer module is buried code which builds list of modules
    # and it uses Package module to query available packages
    Yast.import "HttpServerPackages"
    Yast.import "HttpServer"

    allow(Yast::HttpServerPackages)
      .to receive(:by_provides_regexp)
      .and_return(["php8"])
  end

  # it is included in http server module
  subject { Yast::HttpServer }

  describe "#listen2item" do
    it "returns Item with \"all addresses\" and port number for port number only" do
      expect(subject.listen2item("128", :first)).to eq Item(Id(:first), "All Addresses", "128")
    end

    it "returns Item with address and port number for adrress with port number" do
      expect(subject.listen2item("127.0.0.1:128", :first)).to eq Item(Id(:first), "127.0.0.1", "128")
    end

    it "return Item with id specified in second argument" do
      expect(subject.listen2item("127.0.0.1:128", :first)).to eq Item(Id(:first), "127.0.0.1", "128")
    end
  end

  describe "#listen2map" do
    it "returns hash with \"address\" \"all\" and port number for port number only" do
      expect(subject.listen2map("128")).to eq("port" => "128", "address" => "all")
    end

    it "returns hash with address and port number for address with port number" do
      expect(subject.listen2map("127.0.0.1:128")).to eq("port" => "128", "address" => "127.0.0.1")
    end
  end
end
