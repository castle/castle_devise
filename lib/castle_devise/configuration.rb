# frozen_string_literal: true

module CastleDevise
  class Configuration
    include ActiveSupport::Configurable

    config_accessor(:api_secret)
    config_accessor(:app_id)

    config_accessor(:logger) { Rails.logger }
  end
end
