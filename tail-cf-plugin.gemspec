# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "tail-cf-plugin"
  spec.version       = '0.0.1'
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Pivotal"]
  spec.email         = ["support@cloudfoundry.gor"]
  spec.description   = "CF command line tool to tail CF Application Logs"
  spec.summary       = "CF Tail"
  spec.homepage      = "http://github.com/cloudfoundry/tail-cf-plugin"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -- lib/* `.split("\n") + %w(README.md)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  spec.add_dependency "cf", "~>3.0.0"
end
