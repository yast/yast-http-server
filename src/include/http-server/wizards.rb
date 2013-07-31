# encoding: utf-8

# File:	include/http-server/wizards.ycp
# Package:	Configuration of http-server
# Summary:	Wizards definitions
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
module Yast
  module HttpServerWizardsInclude
    def initialize_http_server_wizards(include_target)
      Yast.import "UI"

      textdomain "http-server"

      Yast.import "Label"
      Yast.import "Sequencer"
      Yast.import "Wizard"
      Yast.import "Directory"

      Yast.include include_target, "http-server/complex.rb"
      Yast.include include_target, "http-server/dialogs.rb"
      Yast.include include_target, "http-server/wizard-dialog.rb"
    end

    def VirtualHostSequence(action)
      aliases = {
        "host"     => lambda { HostDialog() },
        "addhost"  => lambda { AddHost() },
        "setvhost" => lambda { SetVHostOptions() },
        "ssl"      => lambda { SSLDialog() },
        "dir"      => lambda { DirDialog() }
      }

      _def = action == "add" ? "addhost" : "host"
      sequence = {
        "ws_start" => _def,
        "host"     => {
          :abort => :abort,
          :next  => :next,
          #"overview",
          :ssl   => "ssl",
          :dir   => "dir"
        },
        "addhost"  => { :abort => :abort, :next => "setvhost" },
        "setvhost" => {
          :abort => :abort,
          :next  => :next,
          #"overview",
          :back  => "addhost"
        },
        "ssl"      => { :abort => :abort, :next => "host", :back => "host" },
        "dir"      => { :abort => :abort, :next => "host", :back => "host" }
      }

      Sequencer.Run(aliases, sequence)
    end
    def MainSequence
      aliases = {
        "overview" => lambda { OverviewDialog() },
        "addhost"  => lambda { AddHost() },
        "setvhost" => lambda { SetVHostOptions() },
        "dir"      => lambda { DirDialog() },
        "add-vh"   => [lambda { VirtualHostSequence("add") }, true],
        "edit-vh"  => [lambda { VirtualHostSequence("edit") }, true]
      }

      sequence = {
        "ws_start" => "overview",
        "overview" => {
          :abort => :abort,
          :next  => :next,
          :dir   => "dir",
          :edit  => "edit-vh",
          :add   => "add-vh"
        },
        "add-vh" =>
          #`next
          { :abort => :abort, :next => "overview" },
        "edit-vh" =>
          #`next
          { :abort => :abort, :next => "overview" },
        "setvhost" => {
          :abort => :abort,
          :next  => "overview",
          :back  => "addhost"
        },
        "dir"      => {
          :abort => :abort,
          :next  => "overview",
          :back  => "overview"
        }
      }

      ret = Sequencer.Run(aliases, sequence)

      ret
    end

    # Sequences for wizard mode
    # @return sequence result

    def WizardSequence
      aliases = {
        "network-device" => lambda { WizardSequence1() },
        "modules"        => lambda { WizardSequence2() },
        "defhost"        => lambda { WizardSequence3() },
        "hosts"          => lambda { WizardSequence4() },
        "summary"        => lambda { WizardSequence5() },
        "addhost"        => lambda { AddHost() },
        "setvhost"       => lambda { SetVHostOptions() },
        "ssl"            => lambda { SSLDialog() },
        "dir"            => lambda { DirDialog() },
        "main"           => lambda { MainSequence() },
        "host"           => lambda { HostDialog() }
      }

      sequence = {
        "ws_start"       => "network-device",
        "network-device" => { :abort => :abort, :next => "modules" },
        "modules"        => { :abort => :abort, :next => "defhost" },
        "defhost"        => {
          :abort => :abort,
          :next  => "hosts",
          :ssl   => "ssl",
          :dir   => "dir"
        },
        "ssl"            => { :abort => :abort, :next => "defhost" },
        "dir"            => { :abort => :abort, :next => "defhost" },
        "hosts"          => {
          :abort => :abort,
          :next  => "summary",
          :add   => "addhost",
          :edit  => "host"
        },
        "addhost"        => {
          :abort => :abort,
          :next  => "setvhost",
          :back  => "hosts"
        },
        "setvhost"       => {
          :abort => :abort,
          :next  => "hosts",
          :back  => "addhost"
        },
        "summary"        => {
          :abort  => :abort,
          :next   => :next,
          :expert => "main"
        },
        "host"           => {
          :abort => :abort,
          :ssl   => "ssl",
          :next  => "hosts",
          :dir   => "dir"
        },
        "main"           => { :abort => :abort, :next => :next }
      }

      ret = Sequencer.Run(aliases, sequence)
      ret
    end

    # Sequences for whole server
    # @return [Boolean] correct finish
    def HttpServerSequence
      aliases = {
        "read"   => [lambda { ReadDialog() }, true],
        "main"   => lambda { MainSequence() },
        "wizard" => lambda { WizardSequence() },
        "write"  => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "wizard"   => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("http-server")

      w_mode = HttpServer.isWizardMode
      Ops.set(sequence, ["read", :next], "wizard") if w_mode

      ret = Sequencer.Run(aliases, sequence)
      HttpServer.setWizardMode(false) if w_mode

      UI.CloseDialog
      ret == :next
    end

    # Whole configuration of http-server but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def HttpServerAutoSequence
      # translators: initialization dialog caption
      caption = _("HTTP Server Configuration")
      # translators: initialization dialog message
      contents = Label(_("Initializing ..."))

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("http-server")
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      ret
    end
  end
end
