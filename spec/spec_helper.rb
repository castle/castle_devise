# frozen_string_literal: true

require "simplecov"
SimpleCov.start

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy_app/config/environment.rb", __FILE__)
require "rspec/rails"
require "castle_devise"

require "webmock/rspec"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].sort.each { |f| require f }

Rails.backtrace_cleaner.remove_silencers!

ActiveRecord::MigrationContext.new(
  File.expand_path("../dummy_app/db/migrate", __FILE__),
  ActiveRecord::SchemaMigration
).migrate

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.mock_with :rspec
  config.use_transactional_fixtures = true

  config.include Warden::Test::Helpers
  config.include ResponseHelper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after do
    Warden.test_reset!
  end
end
