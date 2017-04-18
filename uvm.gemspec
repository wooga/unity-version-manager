# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/uvm/version"

Gem::Specification.new do |gem|
  gem.name          = "wooga_uvm"
  gem.version       = Uvm::VERSION
  gem.summary       = "Switch between multiple versions of unity"
  gem.description   = "A command line utility to help manage multiple versions of unity on the same machine."
  gem.authors       = ["Donald Hutchison", "Manfred Endres"]
  gem.email         = ["donald.hutchison@wooga.net", "manfred.endres@wooga.net"]
  gem.homepage      = "https://github.com/wooga/unity-version-manager"
  gem.license       = "MIT"

  gem.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|pkg)/}) }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 2.0"
  gem.add_runtime_dependency "plist", "~> 3.2"
  gem.add_runtime_dependency "docopt", "~> 0.5"

  gem.add_development_dependency "bundler", "~> 1.10"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "ZenTest", "~> 4.11"
  gem.add_development_dependency "rspec", "~> 3.5"
  gem.add_development_dependency "rspec-autotest", "~> 1"
  gem.add_development_dependency "rspec-temp_dir", "~> 0"
  gem.add_development_dependency "codeclimate-test-reporter", "~> 1.0"
  gem.add_development_dependency "climate_control", "~> 0.1"
  gem.add_development_dependency "resona", "~> 0.2"
  gem.add_development_dependency "pry-byebug", "~> 3.4"
  gem.add_development_dependency "octokit", "~> 4.3"
  gem.add_development_dependency "httpclient", "2.8.1"
end
