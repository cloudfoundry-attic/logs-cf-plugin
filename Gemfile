source 'https://rubygems.org'

# Specify your gem's dependencies in logs-cf-plugin.gemspec
gemspec

# These are here because Travis bundles without development
group :test do
  gem "rake", "~> 10.1.0"
  gem "rspec", "~> 2.14.0"
  gem "thin", "~> 1.5.1"
  # Pulling from git until https://github.com/faye/faye-websocket-ruby/pull/31
  # is merged in.
  gem "faye-websocket", git: "https://github.com/nwade/faye-websocket-ruby"
end
