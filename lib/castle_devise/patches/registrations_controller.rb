# frozen_string_literal: true

module CastleDevise
  module Patches
    # Monkey-patch for
    # {https://github.com/heartcombo/devise/blob/master/app/controllers/devise/registrations_controller.rb Devise::RegistrationsController}
    # which includes Castle in the registration workflow.
    module RegistrationsController
      extend ActiveSupport::Concern

      included do
        before_action :castle_filter, only: :create
      end

      # Sends a /v1/filter request to Castle
      def castle_filter
        return unless resource_class.castle_hooks[:before_registration]

        response = CastleDevise.sdk_facade.filter(
          event: "$registration",
          context: CastleDevise::Context.from_rack_env(request.env, resource_name)
        )

        return if CastleDevise.monitoring_mode?

        case response.dig(:policy, :action)
        when "deny"
          set_flash_message!(:alert, "blocked_by_castle")
          flash.alert = "Account cannot be created at this moment. Please try again later."
          redirect_to new_session_path(resource_name)
          false
        else
          # everything fine, continue
        end
      rescue Castle::InvalidParametersError
        # TODO: We should act differently if the error is about missing/invalid request token
        #   compared to any other validation errors. However, we can't do this with the
        #   current Castle SDK as it doesn't give us any way to differentiate these two cases.
        CastleDevise.logger.warn(
          "[CastleDevise] /v1/filter request contained invalid parameters." \
          " This might mean that either you didn't configure Castle's Javascript properly, or" \
          " a request has been made without Javascript (eg. cURL/bot)." \
          " Such a request is treated as if Castle responded with a 'deny' action in non-monitoring mode."
        )

        unless CastleDevise.monitoring_mode?
          set_flash_message!(:alert, "blocked_by_castle")
          redirect_to new_session_path(resource_name)
          false
        end
      rescue Castle::Error => e
        # log API errors and allow
        CastleDevise.logger.error("[CastleDevise] filter($registration): #{e}")
      end
    end
  end
end
