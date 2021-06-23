# frozen_string_literal: true

module CastleDevise
  module Controllers
    # Methods defined here will be included in all your controllers.
    module Helpers
      # @return [Castle::Client]
      def castle
        CastleDevise.castle
      end

      # Returns a Castle response from /v1/risk endpoint, if such a request has been made
      # during the request.
      #
      # @return [Hash, nil]
      def castle_risk_response
        request.env["castle_devise.risk_response"]
      end

      # Returns true if Castle Risk API call resulted in a "challenge" action.
      # Returns false if no request has been made, or the action was different than "challenge".
      #
      # @return [true, false]
      def castle_challenge?
        castle_risk_response&.dig(:policy, :action) == "challenge"
      end
    end
  end
end
