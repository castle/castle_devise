# frozen_string_literal: true

module CastleDevise
  class << self
    delegate :logger, to: :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration

      Castle.api_secret = configuration.api_secret
      Castle.config.logger = configuration.logger
    end
  end
end

require_relative "castle_devise/configuration"
require_relative "castle_devise/patches"
require_relative "castle_devise/controllers/helpers"
require_relative "castle_devise/helpers/castle_helper"
require_relative "castle_devise/hooks/castle_protectable"
require_relative "castle_devise/models/castle_protectable"
require_relative "castle_devise/patches/registrations_controller"

require_relative "castle_devise/rails"

Devise.add_module :castle_protectable, model: "castle_devise/models/castle_protectable"
