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
        response = CastleDevise.sdk_facade.filter(
          event: "$registration",
          context: CastleDevise::Context.from_rack_env(request.env, resource_name)
        )

        return if CastleDevise.monitoring_mode?

        case response.dig(:policy, :action)
        when "deny"
          flash.alert = "Account cannot be created at this moment. Please try again later"
          redirect_to new_session_path(resource_name)
          false
        else
          # everything fine, continue
        end
      rescue Castle::Error => e
        # log API errors and allow
        logger.info "#{e}: #{e.message}"
      end
    end
  end
end
