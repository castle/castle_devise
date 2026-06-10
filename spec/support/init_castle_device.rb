# frozen_string_literal: true

CastleDevise.configure do |config|
  # Explicitly set a non-empty api_secret. The castle-rb SDK validates that
  # api_secret is present before every request, and the VCR cassettes mean
  # no real secret is needed, so a fixed dummy value keeps the specs valid
  # everywhere (including Dependabot runs that don't get repo secrets).
  config.api_secret = "fake-secret-123"
  config.app_id = "123456789"
  config.logger = Logger.new($stdout)
end
