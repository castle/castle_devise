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

    # @!attribute monitoring_mode
    #   When CastleDevise is in monitoring mode, it sends requests to Castle
    #   but it doesn't act on "deny" verdicts.
    #
    #   This mode is useful if you're just checking Castle out and you're not yet sure whether
    #   your configuration is correct so you don't accidentally block legitimate users
    #   from logging in/registering.
    #
    #   @return [true, false] whether to act on deny requests or not
    config_accessor(:monitoring_mode) { false }

    # @!attribute logger
    #   @return [Logger] A Logger instance. You might want to use Rails.logger here.
    config_accessor(:logger) { Logger.new('/dev/null') }
  end
end
