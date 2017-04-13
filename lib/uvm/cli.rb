require 'thor'
require 'fileutils'
require 'wooget/util/misc'
module UVM
  UNITY_LINK='/Applications/Unity'
  UNITY_CONTENTS="#{UNITY_LINK}/Unity.app/Contents"
  UNITY_INSTALL_LOCATION='/Applications'

  class CLI < Thor

    def initialize args, local_options, config
      super(args, local_options, config)
      ensure_link
    end

    desc "list", "list unity versions available"
    def list
      installed = Lib.list
      current = Lib.current
      puts installed.map {|i| (!current.nil? and current.include?(i)) ? i + " [active]" : i }
    end

    desc "use VERSION", "Use specific version of unity"
    def use version
      unless version =~ Lib.version_regex
        puts "Invalid format '#{version}' - please try a version in format `X.X.X`"
        exit
      end

      desired_version = File.join(UNITY_INSTALL_LOCATION,"Unity"+version)

      unless Dir.exists? desired_version
        puts "Version #{version} isn't available "
        puts "Available versions are -"
        list
        exit
      end

      FileUtils.rm(UNITY_LINK) if File.exists? UNITY_LINK
      FileUtils.ln_s(desired_version, UNITY_LINK, :force => true)

      puts "Using #{version} : #{UNITY_LINK} -> #{desired_version}"
    end

    desc "clear", "Remove the link so you can install a new version without overwriting"
    def clear
      if File.symlink?(UNITY_LINK)
        FileUtils.rm(UNITY_LINK)
      end
    end

    desc "detect", "Find which version of unity was used to generate the project in current dir"
    def detect
      version = `find . -name ProjectVersion.txt | xargs cat | grep EditorVersion`
      match_data = version.match /m_EditorVersion: (.*)/

      if match_data and match_data.length > 1
        puts match_data[1]
      else
        puts "Couldn't detect project version"
      end
    end

    desc "current", "Print the current version in use"
    def current
      if Lib.current
        puts Lib.current
      else
        puts "No unity version detected"
      end
    end

    desc "launch [PATH=pwd] [PLATFORM=android]", "Launch the current version of unity"
    def launch project_path=File.expand_path(Dir.pwd), platform="android"
      project_str = ""
      project_str = "-projectPath '#{project_path}'" if Wooget::Util.is_a_unity_project_dir(project_path)

      exec "open #{UNITY_LINK}/Unity.app --args -buildTarget #{platform} #{project_str}"
    end

    private
    def ensure_link
      if !File.symlink?(UNITY_LINK) and File.directory?(UNITY_LINK)
        new_dir_name = File.join(UNITY_INSTALL_LOCATION,"Unity"+Lib.current)
        FileUtils.mv(UNITY_LINK, new_dir_name)
        FileUtils.ln_s(new_dir_name, UNITY_LINK, :force => true)
      end
    end
  end

  class Lib
    def self.current
      plist_path = File.join(UNITY_CONTENTS,"Info.plist")
      if File.exists? plist_path
        `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{plist_path}`.split("f").first
      end
    end

    def self.list
      installed = `find #{UNITY_INSTALL_LOCATION} -name "Unity*" -type d -maxdepth 1`.lines
      installed.map{|u| u.match(version_regex){|m| m[1]} }
    end

    def self.version_regex
      /(\d+\.\d+\.\d+(f\d+)?)/
    end
  end
end
