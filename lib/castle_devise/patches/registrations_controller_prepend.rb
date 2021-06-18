# frozen_string_literal: true

module CastleDevise
  module Patches
    module RegistrationsControllerPrepend
      extend ActiveSupport::Concern

      def create
        super do |resource|
          castle_risk(resource)
        end
      end

      # @param resource [ActiveRecord::Base]
      def castle_risk(resource)
        CastleDevise.sdk_facade.risk(
          event: "$registration",
          context: CastleDevise::Context.from_rack_env(request.env, resource, resource_name)
        )
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
