# frozen_string_literal: true

module CastleDevise
  module Patches
    # Monkey-patch for
    # {https://github.com/heartcombo/devise/blob/master/app/controllers/devise/passwords_controller.rb Devise::PasswordsController}
    # which includes Castle to the password reset requests flow.
    module PasswordsController
      extend ActiveSupport::Concern

      # PUT /resource/password
      # @note Notice, all these steps must happen within a block because before calling
      #   "reset_password_by_token" method we don't know what resource we operate on.
      def update
        super do |resource|
          next unless resource_class.castle_hooks[:profile_update]

          context = CastleDevise::Context.from_rack_env(request.env, scope_name, resource)

          begin
            # No need for a verification mechanism here because this action is performed after
            # clicking on the password reset link with a token.
            CastleDevise.sdk_facade.risk(
              event: "$profile_update",
              status: "$attempted",
              context: context
            )
          rescue Castle::InvalidParametersError
            # TODO: We should act differently if the error is about missing/invalid request token
            #   compared to any other validation errors. However, we can't do this with the
            #   current Castle SDK as it doesn't give us any way to differentiate these two cases.
            CastleDevise.logger.warn(
              "[CastleDevise] /v1/risk request contained invalid parameters." \
              " This might mean that either you didn't configure Castle's Javascript properly," \
              " or a request has been made without Javascript (eg. cURL/bot)." \
              " Such a request is treated as if Castle responded with a 'deny' action in" \
              " non-monitoring mode."
            )
          rescue Castle::Error => e
            # log API errors and allow
            CastleDevise.logger.error("[CastleDevise] risk($profile_update): #{e}")
          end

          begin
            CastleDevise.sdk_facade.log(
              event: "$profile_update",
              status: resource.errors.empty? ? "$succeeded" : "$failed",
              context: context
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
