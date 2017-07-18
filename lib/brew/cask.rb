require "open3"

module Brew
  class Cask

    def search pattern
      results = []

      Open3.popen3("brew cask search", pattern) {|i,o,e,t|
        results = o.read.chomp.lines.map { |i| i.chomp }
      }

      results.select {|item| !item.start_with? "==>" }
    end

    def install name
      Open3.popen3("brew cask install", name) {|i,o,e,t|
      }
    end
  end
end
