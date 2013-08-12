# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "tail-cf-plugin"
  spec.version       = '0.0.21.pre'
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Pivotal"]
  spec.email         = ["vcap-dev@googlegroups.com"]
  spec.description   = "CF command line tool to tail CF Application Logs"
  spec.summary       = "CF Tail"
  spec.homepage      = "http://github.com/cloudfoundry/tail-cf-plugin"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -- lib/* vendor/*`.split("\n") + %w(README.md)
  spec.require_paths = ["lib", "vendor"]

  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  spec.add_dependency "cf", ">= 4.2.5", "< 5.0"
  spec.add_dependency "faye-websocket", "~> 0.6.1"
  spec.add_dependency "beefcake", "~> 0.3.7"
end
