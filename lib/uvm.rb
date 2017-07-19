#!/usr/bin/env ruby

require_relative "uvm/version"
require_relative "uvm/uvm"
require "set"

module Uvm
  @version_manager = Uvm.new

  class CLIDispatch
    def initialize version_manager, options
      @version_manager = version_manager
      @options = options
    end

    def dispatch
      raise "No options provided" if @options.nil? or @options.empty?

      @options.each_key do |key|
        method_name = "dispatch_#{key}"
        if self.respond_to? method_name
          self.public_send(method_name) 
          return
        end
      end

      raise "Unknown command"
    end

    def dispatch_current
      begin
        current = @version_manager.current
        $stdout.puts current
      rescue => e
        abort e.message
      end
    end

    def dispatch_list
      l = @version_manager.list
      $stderr.puts "Installed Unity versions:"
      $stderr.puts "None" if l.empty?
      $stdout.puts l
    end

    def dispatch_use
      v = @options['<version>']
      begin
        new_path = @version_manager.use version: v
        $stdout.puts "Using #{v} : #{UNITY_LINK} -> #{new_path}"
      rescue ArgumentError => e
        abort e.message
      rescue
        $stderr.puts "Version #{v} isn't available"
        $stderr.puts "Available versions are:"
        $stderr.puts @version_manager.list
        exit 1
      end
    end

    def dispatch_clear
      begin
        c = @version_manager.current
        @version_manager.clear
        $stdout.puts "Clear active Unity version old: #{c}"
      rescue => e
        abort e.message
      end
    end

    def dispatch_detect
      begin
        version = @version_manager.detect
        $stdout.puts version
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

    def dispatch_versions
      l = @version_manager.versions
      i = @version_manager.list mark_active:false
      l = (l.to_set - i.to_set)

      $stderr.puts "Available Unity versions:"
      $stderr.puts "None" if l.empty?
      $stdout.puts l.to_a
    end

    def dispatch_install           
      @version_manager.install **create_install_opts
    end

    def dispatch_uninstall            
      @version_manager.uninstall **create_install_opts
    end

    private

    def create_install_opts
      opts = {
        version: @options['<version>'],
        ios: (@options['--ios'] || @options['--mobile'] || @options['--all']),
        android: (@options['--android'] || @options['--mobile'] || @options['--all']),
        webgl: (@options['--webgl'] || @options['--mobile'] || @options['--all']),
        linux: (@options['--linux'] || @options['--desktop'] || @options['--all']),
        windows: (@options['--windows'] || @options['--desktop'] || @options['--all'])
      }
    end
  end

  def self.dispatch options
    d = CLIDispatch.new Uvm.new, options
    d.dispatch()
  end
end