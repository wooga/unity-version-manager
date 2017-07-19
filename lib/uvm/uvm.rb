require 'plist'
require 'fileutils'
require 'brew/cask'
require 'brew/tap'

module Uvm
  
  UNITY_INSTALL_LOCATION='/Applications'
  UNITY_LINK="#{UNITY_INSTALL_LOCATION}/Unity"
  UNITY_CONTENTS="#{UNITY_LINK}/Unity.app/Contents"
  
  class Uvm

    attr_reader :tap, :cask

    def initialize tap: nil, cask: nil
      ensure_link
      @tap = tap.nil? ? Brew::Tap.new : tap
      @cask = cask.nil? ? Brew::Cask.new : cask
    end

    # returns a list of installed unity version in the form of
    # major.minor.path(p|f)level
    # if no unity versions are installed returns an empty list
    
    def list mark_active: true, **options
      pattern = File.join UNITY_INSTALL_LOCATION, "Unity-*"
      versions = Dir.glob(pattern).select{|u| !u.match(version_regex).nil? }.map{|u| u.match(version_regex){|m| m[1]} }
      current = mark_active ? current(**options) : ""
      versions.map {|u| current.eql?(u) ? u + ' [active]' : u}
    end

    # Sets link to specified unity version.
    # Raise error when version parameter is not in form of major.minor.path(p|f)level
    # or specified version is not installed.

    def use version: :latest, **_options
      unless version =~ version_regex
        raise ArgumentError, "Invalid format '#{version}' - please try a version in format `x.x.x(f|p)x`"
      end

      if current.eql? version
        raise ArgumentError, "Invalid version '#{version}' - version is already active"
      end

      unless list.include? version
        raise "Invalid version '#{version}' - version is not available"
      end

      desired_version = File.join(UNITY_INSTALL_LOCATION,"Unity-"+version)
      FileUtils.rm_f(UNITY_LINK) if File.exist? UNITY_LINK
      FileUtils.ln_s(desired_version, UNITY_LINK, :force => true)
      desired_version
    end

    # Clears current link to active unity
    # Raise error when no unity version is activated 

    def clear **_options
      unless File.exist? UNITY_LINK
        raise "Invalid operation - no version active"
      end

      FileUtils.rm_f UNITY_LINK
    end

    # Detects Unity version in current project

    def detect **_options
      versions_file = File.absolute_path File.join("ProjectSettings","ProjectVersion.txt")
      if File.exist? versions_file
        content = ""
        File.open(versions_file) {|f| content = f.read }
        match_data = content.match(/m_EditorVersion: (.*)/)
        if match_data and match_data.length > 1
          return match_data[1]
        else
          raise "Invalid operation - could not detect project version"          
        end
      end

      raise "Invalid operation - could not detect project"
    end

    # returns current activated unity version
    # returns empty string when no version is activated

    def current **_options
      plist_path = File.join(UNITY_CONTENTS,"Info.plist")
      
      if File.exist? plist_path
        plist = Plist::parse_xml(plist_path)
        return plist['CFBundleVersion']
      end
      ""
    end

    # launch active unity with project path and platform

    def launch project_path: File.expand_path(Dir.pwd), platform: "android", **_options
      project_str = ""
      project_str = "-projectPath '#{project_path}'" if is_a_unity_project_dir? project_path

      exec "open #{UNITY_LINK}/Unity.app --args -buildTarget #{platform} #{project_str}"
    end

    # list available versions to download

    def versions **options
      unless tap.include? "wooga/unityversions"
        tap.add "wooga/unityversions"
      end
      cask.search("unity").select {|cask| cask.match /unity@/}.map{|cask| cask.split("@")[1]}
    end

    # install unity via brew cask

    def install version: :latest, ios:false, android:false, webgl:false, linux:false, windows:false, **options
      unless tap.include? "wooga/unityversions"
        tap.add "wooga/unityversions"
      end

      to_install = ["unity@#{version}"]
      to_install << "unity-ios-support-for-editor@#{version}" if ios
      to_install << "unity-android-support-for-editor@#{version}" if android
      to_install << "unity-webgl-support-for-editor@#{version}" if webgl
      to_install << "unity-linux-support-for-editor@#{version}" if linux
      to_install << "unity-windows-support-for-editor@#{version}" if windows

      cask.install(*to_install)
    end

    # uninstall unity via brew cask

    def uninstall version: :latest, ios:false, android:false, webgl:false, linux:false, windows:false, **options
      unless tap.include? "wooga/unityversions"
        tap.add "wooga/unityversions"
      end

      installed = cask.list.select {|cask| cask.include? "@#{version}"}

      to_uninstall = []
      to_uninstall << "unity-ios-support-for-editor@#{version}" if ios
      to_uninstall << "unity-android-support-for-editor@#{version}" if android
      to_uninstall << "unity-webgl-support-for-editor@#{version}" if webgl
      to_uninstall << "unity-linux-support-for-editor@#{version}" if linux
      to_uninstall << "unity-windows-support-for-editor@#{version}" if windows

      to_uninstall = installed if to_uninstall.empty?

      cask.uninstall(*to_uninstall)
    end

    protected

    def is_a_unity_project_dir? path
      contents = Dir[File.join(path, "*")].map { |c| File.basename(c) }
      contents.include?("Assets") and contents.include?("ProjectSettings")
    end

    def version_regex
      /(\d+\.\d+\.\d+((f|p)\d+)?)$/
    end

    def ensure_link
      if !File.symlink?(UNITY_LINK) and File.directory?(UNITY_LINK)
        new_dir_name = File.join(UNITY_INSTALL_LOCATION,"Unity-"+current)
        FileUtils.mv(UNITY_LINK, new_dir_name)
        FileUtils.ln_s(new_dir_name, UNITY_LINK, :force => true)
      end
    end
  end
end