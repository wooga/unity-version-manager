#!/usr/bin/env ruby

require_relative "uvm/version"
require_relative "uvm/uvm"

module Uvm
  @version_manager = Uvm.new

  class CLIDispatch
    def initialize version_manager, options
      @version_manager = version_manager
      @options = options
    end

    def dispatch
      @options.each_key do |key|
        method_name = "dispatch_#{key}"
        self.public_send(method_name) if self.respond_to? method_name
      end
    end

    def dispatch_current
      begin
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
  end

  def self.dispatch options
    d = CLIDispatch.new Uvm.new, options
    d.dispatch()
  end
end