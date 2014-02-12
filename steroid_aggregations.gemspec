# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'steroid_aggregations/version'

Gem::Specification.new do |spec|
  spec.name          = "steroid_aggregations"
  spec.version       = SteroidAggregations::VERSION
  spec.authors       = ["Romeu Fonseca"]
  spec.email         = ["romeu.hcf@gmail.com"]
  spec.description   = %q{ActiveRecord plugin for counter cache and other kinds of aggregations}
  spec.summary       = %q{... will be written, soon!}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency "activerecord"
  spec.add_development_dependency "sqlite3"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "simplecov"

end
