# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "logs-cf-plugin"
  spec.version       = '0.0.44.pre'
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Pivotal"]
  spec.email         = ["vcap-dev@googlegroups.com"]
  spec.description   = "CF command line tool to retrieve recent and tail CF Application Logs"
  spec.summary       = "CF Logs"
  spec.homepage      = "http://github.com/cloudfoundry/logs-cf-plugin"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -- lib/* vendor/*`.split("\n") + %w(README.md)
  spec.require_paths = ["lib", "vendor"]

  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  spec.post_install_message = "+"*60 +
      "\nThe logs-cf-plugin gem is deprecated. Please use the new CLI\nto access application logging.\n\n  URL: https://github.com/cloudfoundry/cli\n" + "+"*60 + "\n\n"

  spec.add_dependency "cf", "~> 5.0"
end
