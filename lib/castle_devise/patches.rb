# frozen_string_literal: true

module CastleDevise
  module Patches
    class << self
      def apply
        Devise::RegistrationsController.send(:include, Patches::RegistrationsController)
        Devise::SessionsController.send(:include, Patches::SessionsController)
      end
    end
  end
end
