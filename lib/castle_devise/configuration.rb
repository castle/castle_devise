# frozen_string_literal: true

require "active_support/configurable"
require "logger"

module CastleDevise
  class Configuration
    include ActiveSupport::Configurable

    config_accessor(:api_secret)
    config_accessor(:app_id)

    config_accessor(:logger) { Logger.new('/dev/null') }
  end
end
