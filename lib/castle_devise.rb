# frozen_string_literal: true

require "castle"
require "devise"

module CastleDevise
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def logger
      configuration.logger
    end

    def configure
      yield configuration

      Castle.api_secret = configuration.api_secret
      Castle.config.logger = configuration.logger
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
require_relative "castle_devise/patches/registrations_controller_prepend"

require_relative "castle_devise/rails"

Devise.add_module :castle_protectable, model: "castle_devise/models/castle_protectable"
