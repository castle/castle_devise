# frozen_string_literal: true

CastleDevise.configure do |config|
  config.api_secret = ENV.fetch("CASTLE_API_SECRET", "fake-secret-123")
  config.app_id = ENV.fetch("CASTLE_APP_ID", "123456789")
  config.logger = Logger.new($stdout)
end
