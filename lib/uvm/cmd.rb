module Uvm
  
  UNITY_INSTALL_LOCATION='/Applications'
  UNITY_LINK="#{UNITY_INSTALL_LOCATION}/Unity"
  UNITY_CONTENTS="#{UNITY_LINK}/Unity.app/Contents"
  
  
  class Cmd    

    def initialize
      ensure_link
    end


    # returns a list of installed unity version in the form of
    # major.minor.path(p|f)level
    # if no unity versions are installed returns an empty list
    
    def list **options
      pattern = File.join UNITY_INSTALL_LOCATION, "Unity-*"
      versions = Dir.glob(pattern).select{|u| !u.match(version_regex).nil? }.map{|u| u.match(version_regex){|m| m[1]} }
      current = current(**options)
      versions.map {|u| current.eql?(u) ? u + ' [active]' : u}
    end

    
    def use version: :latest, **options
      unless version =~ version_regex
        raise "Invalid format '#{version}' - please try a version in format `x.x.x(f|p)x`"
      end

      unless list.include? version
        raise "Invalid version '#{version}' - version is not available"
      end

      desired_version = File.join(UNITY_INSTALL_LOCATION,"Unity-"+version)
      FileUtils.rm_f(UNITY_LINK) if File.exists? UNITY_LINK
      FileUtils.ln_s(desired_version, UNITY_LINK, :force => true)
    end

    def clear **options
      unless File.exist? UNITY_LINK
        raise "Invalid operation - no version active"
      end

      FileUtils.rm_f UNITY_LINK
    end

    def detect **options
      versions_file = File.absolute_path File.join("ProjectSettings","ProjectVersion.txt")
      if File.exists? versions_file
        content = ""
        File.open(versions_file) {|f| content = f.read }
        match_data = content.match /m_EditorVersion: (.*)/
        if match_data and match_data.length > 1
          return match_data[1]
        else
          raise "Invalid operation - could not detect project version"          
        end
      end

      raise "Invalid operation - could not detect project"
    end

    def current **options
      plist_path = File.join(UNITY_CONTENTS,"Info.plist")
      
      if File.exists? plist_path
        return `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{plist_path}`.strip
      end
      ""
    end

    protected
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