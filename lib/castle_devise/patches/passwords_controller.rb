# frozen_string_literal: true

module CastleDevise
  module Patches
    # Monkey-patch for
    # {https://github.com/heartcombo/devise/blob/master/app/controllers/devise/passwords_controller.rb Devise::PasswordsController}
    # which includes Castle to the password reset requests flow.
    module PasswordsController
      extend ActiveSupport::Concern

      # PUT /resource/password
      # @note Notice, this must happen within a block because before calling
      #   "reset_password_by_token" method we don't know what resource we operate on.
      def update
        super do |resource|
          next unless resource_class.castle_hooks[:profile_update]

          begin
            CastleDevise.sdk_facade.log(
              event: "$profile_update",
              status: resource.errors.empty? ? "$succeeded" : "$failed",
              context: CastleDevise::Context.from_rack_env(request.env, scope_name, resource)
            )
          rescue Castle::Error => e
            # log API errors and pass-through it
            CastleDevise.logger.error("[CastleDevise] log($password_reset_request): #{e}")
          end
        end
      end

      # POST /resource/password
      def create
        super do |resource|
          next unless resource_class.castle_hooks[:after_password_reset_request]

          begin
            CastleDevise.sdk_facade.log(
              event: "$password_reset_request",
              status: resource.persisted? ? "$succeeded" : "$failed",
              context: CastleDevise::Context.from_rack_env(request.env, scope_name, resource)
            )
          rescue Castle::Error => e
            # log API errors and pass-through it
            CastleDevise.logger.error("[CastleDevise] log($password_reset_request): #{e}")
          end
        end
      end
    end
  end
end
