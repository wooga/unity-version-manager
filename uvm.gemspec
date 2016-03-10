# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/uvm/version"

Gem::Specification.new do |gem|
  gem.name          = "wooga_uvm"
  gem.version       = Uvm::VERSION
  gem.summary       = "Switch between multiple versions of unity"
  gem.description   = "A command line utility to help manage multiple versions of unity on the same machine."
  gem.authors       = ["Donald Hutchison"]
  gem.email         = ["donald.hutchison@wooga.net"]
  gem.homepage      = "https://github.com/wooga/unity-version-manager"
  gem.license       = "MIT"

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^pkg/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 2.0"
  gem.add_runtime_dependency "thor"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "pry-byebug"

end
