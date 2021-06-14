# frozen_string_literal: true

module CastleDevise
  # A Facade layer providing a simpler API on top of the Castle SDK
  class SdkFacade
    attr_reader :castle

    # @param castle [Castle::Client]
    def initialize(castle)
      @castle = castle
    end

    # @param event [String]
    # @param context [CastleDevise::Context]
    def filter(event:, context:)
      castle.filter(
        event: event,
        request_token: context.request_token,
        context: Castle::Context::Prepare.call(context.rack_request)
      )
    end

    # @param event [String]
    # @param context [CastleDevise::Context]
    def risk(event:, context:)
      castle.risk(
        event: event,
        status: "$succeeded",
        user: {
          id: context.castle_id,
          email: context.email,
          registered_at: context.registered_at.utc.iso8601(3),
          traits: context.user_traits
        },
        request_token: context.request_token,
        context: Castle::Context::Prepare.call(context.rack_request)
      )
    end
  end
end
