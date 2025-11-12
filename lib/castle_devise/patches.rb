# frozen_string_literal: true

module CastleDevise
  module Patches
    class << self
      # Applies monkey-patches to Devise controllers
      # @api private
      def apply
        Devise::RegistrationsController.prepend Patches::RegistrationsController
        Devise::PasswordsController.prepend Patches::PasswordsController
      end
    end
  end
end
