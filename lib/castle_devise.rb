# frozen_string_literal: true

require "castle"
require "devise"

# CastleDevise consists of a few different parts:
#
# - Devise castle_protectable module defined in lib/castle_devise/models/
# - Minimal monkey patches to Devise controller defined in lib/castle_devise/patches/
# - Warden hooks defined in lib/castle_devise/hooks/
# - A Facade layer on top of the Castle SDK: {CastleDevise::SdkFacade}
# - A Context object that contains all the data you might want to use when integrating
#   Castle with your application: {CastleDevise::Context}
module CastleDevise
  class << self
    # @return [CastleDevise::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # @return [Logger]
    def logger
      configuration.logger
    end

    # @yieldparam [CastleDevise::Configuration] configuration object
    def configure
      yield configuration

      Castle.api_secret = configuration.api_secret
      Castle.config.logger = configuration.logger
    end

    # @return [true, false] whether in monitoring mode or not
    def monitoring_mode?
      configuration.monitoring_mode
    end

    # @return [CastleDevise::SdkFacade]
    def sdk_facade
      @sdk_facade ||= CastleDevise::SdkFacade.new(castle)
    end

    # @return [Castle::Client]
    def castle
      @castle ||= Castle::Client.new
    end
  end
end

require_relative "castle_devise/configuration"
require_relative "castle_devise/context"
require_relative "castle_devise/patches"
require_relative "castle_devise/sdk_facade"
require_relative "castle_devise/controllers/helpers"
require_relative "castle_devise/helpers/castle_helper"
require_relative "castle_devise/hooks/castle_protectable"
require_relative "castle_devise/models/castle_protectable"
require_relative "castle_devise/patches/registrations_controller"

require_relative "castle_devise/rails"

Devise.add_module :castle_protectable, model: "castle_devise/models/castle_protectable"
