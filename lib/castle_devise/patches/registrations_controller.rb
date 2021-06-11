# frozen_string_literal: true

module CastleDevise
  module Patches
    module RegistrationsController
      extend ActiveSupport::Concern

      included do
        before_action :castle_filter, only: :create
      end

      def castle_filter
        response = castle.filter(
          event: "$registration",
          request_token: params["castle_request_token"],
          context: Castle::Context::Prepare.call(request)
        )

        case response.dig(:policy, :action)
        when "deny"
          flash[:error] = "Account cannot be created at this moment. Please try again later"
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
