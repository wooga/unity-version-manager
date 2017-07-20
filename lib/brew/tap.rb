require "open3"

module Brew
  class Tap
    def include? tap_name
      taps = []
      
      Open3.popen3("brew tap") {|i,o,e,t|
        taps = o.read.chomp.lines.map { |i| i.chomp }
      }
      
      taps.include? tap_name
    end

    def add tap_name
      system "brew tap #{tap_name}"
    end

    def ensure tap_name
      add(tap_name) unless include? tap_name
    end
  end
end