# -*- encoding: utf-8 -*-
require File.expand_path('../lib/optix/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Moe"]
  gem.email         = ["moe@busyloop.net"]
  gem.homepage      = "https://github.com/busyloop/optix"
  gem.has_rdoc      = false
  gem.description   = %q{Optix is an unobtrusive, composable command line parser.}
  gem.summary       = %q{Optix is an unobtrusive, composable command line parser.}

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "optix"
  gem.require_paths = ["lib"]
  gem.version       = Optix::VERSION

  gem.add_dependency "chronic"
  gem.add_development_dependency "simplecov"
end
