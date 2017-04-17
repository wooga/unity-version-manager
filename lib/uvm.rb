#!/usr/bin/env ruby

require_relative "uvm/version"
require_relative "uvm/cli"
require_relative "uvm/uvm"
require 'docopt'

command_name = File.basename(__FILE__)

doc = <<DOCOPT
#{command_name} - Tool that just manipulates a link to the current unity version 

Usage:
  #{command_name} current
  #{command_name} list
  #{command_name} use <version>
  #{command_name} clear
  #{command_name} detect
  #{command_name} version
  #{command_name} (-h | --help)
  #{command_name} --version
  
Options:
--version         print version
-h, --help        show this help message and exit

Commands:
clear             Remove the link so you can install a new version without overwriting
current           Print the current version in use
detect            Find which version of unity was used to generate the project in current dir
help              Describe available commands or one specific command
launch            Launch the current version of unity
list              list unity versions available
use               Use specific version of unity

DOCOPT

module Uvm
  @version_manager = Uvm.new

  def self.dispatch options
    if options['current']
      begin
        current = @version_manager.current
        STDOUT.puts current
      rescue => e
        abort e.message
      end
    end

    if options['list']
      l = @version_manager.list
      STDERR.puts "Installed Unity versions:"
      STDERR.puts "None" if l.empty?
      STDOUT.puts l
    end

    if options['use']
      v = options['<version>']
      begin
        c = @version_manager.current
        @version_manager.use version: v
        STDOUT.puts "Update active Unity version old: #{c} new: #{v}"
      rescue => e
        abort e.message
      end
    end

    if options['clear']
      begin
        c = @version_manager.current
        @version_manager.clear
        STDOUT.puts "Clear active Unity version old: #{c}"
      rescue => e
        abort e.message
      end
    end

    if options['detect']
      begin
        version = @version_manager.detect
        STDOUT.puts version
      rescue => e
        abort e.message
      end
    end

    if options['version'] || options['--version']
      STDOUT.puts VERSION
    end
  end
end

if __FILE__==$0
  options = nil
  begin
    options = Docopt::docopt(doc)
  rescue Docopt::Exit => e
    STDERR.puts e.message
    exit 1
  end

  Uvm.dispatch options 
end