require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module DummyApp
  class Application < Rails::Application
    # Load defaults for the Rails version we're running against. This keeps the dummy
    # app exercising each appraisal gemfile against that Rails version's own defaults.
    config.load_defaults Rails::VERSION::STRING.to_f

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
