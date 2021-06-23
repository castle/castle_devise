# frozen_string_literal: true

require "active_support/configurable"
require "logger"

module CastleDevise
  # Configuration object using {ActiveSupport::Configurable}
  class Configuration
    include ActiveSupport::Configurable

    # @!attribute api_secret
    #   @return [String] Your API secret
    config_accessor(:api_secret)

    # @!attribute app_id
    #   @return [String] Your Castle App ID
    config_accessor(:app_id)

    # @!attribute logger
    #   @return [Logger] A Logger instance. You might want to use Rails.logger here.
    config_accessor(:logger) { Logger.new('/dev/null') }
  end
end
