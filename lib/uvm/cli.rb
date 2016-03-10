require 'thor'
require 'fileutils'

module UVM
  UNITY_LINK='/Applications/Unity'
  UNITY_CONTENTS='/Applications/Unity/Unity.app/Contents'
  UNITY_INSTALL_LOCATION='/Applications'

  class CLI < Thor

    desc "list", "list unity versions available"
    def list
      `find #{UNITY_INSTALL_LOCATION} -name "Unity*" -type d -maxdepth 1`
    end

    desc "use VERSION", "Use specific version of unity"
    def use version
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
      plist_path = File.join(UNITY_CONTENTS,"Info.plist")
      if File.exists? plist_path
        puts `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{plist_path}`
      else
        puts "No unity version detected"
      end
    end
  end
end
¡