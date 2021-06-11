# frozen_string_literal: true

CastleDevise.configure do |config|
  config.api_secret = 'secret123'
  config.app_id = 'app_id_123'
  config.logger = Logger.new($stdout)
end