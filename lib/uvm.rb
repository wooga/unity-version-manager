#!/usr/bin/env ruby

require_relative "uvm/version"
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
  #{command_name} launch [<project-path>] [<platform>]
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

  class CLIDispatch
    def initialize version_manager, options
      @version_manager = version_manager
      @options = options
    end

    def dispatch
      @options.each_pair do |key, value|
        method_name = "dispatch_#{key}"
        self.public_send(method_name) if self.respond_to? method_name
      end
    end

    def dispatch_current
      begin
        puts @version_manager
        current = @version_manager.current
        STDOUT.puts current
      rescue => e
        abort e.message
      end
    end

    def dispatch_list
      l = @version_manager.list
      STDERR.puts "Installed Unity versions:"
      STDERR.puts "None" if l.empty?
      STDOUT.puts l
    end

    def dispatch_use
      v = @options['<version>']
      begin
        c = @version_manager.current
        new_path = @version_manager.use version: v
        STDOUT.puts "Using #{v} : #{UNITY_LINK} -> #{new_path}"
      rescue ArgumentError => e
        abort e.message
      rescue
        STDERR.puts "Version #{v} isn't available"
        STDERR.puts "Available versions are:"
        STDERR.puts @version_manager.list
        exit 1
      end
    end

    def dispatch_clear
      begin
        c = @version_manager.current
        @version_manager.clear
        STDOUT.puts "Clear active Unity version old: #{c}"
      rescue => e
        abort e.message
      end
    end

    def dispatch_detect
      begin
        version = @version_manager.detect
        STDOUT.puts version
      rescue => e
        abort e.message
      end
    end

    def dispatch_launch
      o = {}
      o.merge!({:project_path => options['<project-path>']}) if options['<project-path>']
      o.merge!({:platform => options['<platform>']}) if options['<platform>']
      
      @version_manager.launch(**o)
    end

    def dispatch_version
      STDOUT.puts VERSION
    end
  end

  def self.dispatch options
    d = CLIDispatch.new Uvm.new, options
    d.dispatch()
  end
end

if __FILE__==$0
  options = nil
  begin
    options = Docopt::docopt(doc, version:Uvm::VERSION, help:true)
  rescue Docopt::Exit => e
    STDERR.puts e.message
    exit 1
  end
  
  options = options.delete_if { |key, value| !value }
  Uvm.dispatch options 
end