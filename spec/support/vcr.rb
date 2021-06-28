# frozen_string_literal: true

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock

  config.filter_sensitive_data("<AUTHORIZATION_HEADER>") do |interaction|
    interaction.request.headers["Authorization"].first
  end
end
