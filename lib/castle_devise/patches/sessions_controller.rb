# frozen_string_literal: true

module CastleDevise
  module Patches
    module SessionsController
      extend ActiveSupport::Concern

      included do
        before_action :castle_filter, only: :create
      end

      def castle_filter
        response = CastleDevise.sdk_facade.filter(
          event: "$login",
          context: CastleDevise::Context.from_rack_env(request.env)
        )

        case response.dig(:policy, :action)
        when "deny"
          throw(:warden, scope: resource_name, message: :not_found_in_database)
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
