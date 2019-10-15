#!/usr/bin/env rspec

require_relative "test_helper"
require "http-server/clients/main"

Yast.import "CommandLine"

describe Yast::HttpServerClient do
  describe "#main" do
    before do
      allow(Yast::CommandLine).to receive(:Run)
    end

    it "does not crash" do
      expect { subject.main }.to_not raise_error
    end
  end
end
