require 'thor'

module UVM
  class CLI < Thor

    desc "list", "list unity versions available"
    def list

    end

    desc "use VERSION", "Use specific version of unity"
    def use version

    end

    desc "detect", "Find which version of unity was used to generate the project in current dir"
    def detect

    end

    desc "current", "Print the current version in use"
    def current

    end
  end
end
