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
    # @param rack_request [Rack::Request]
    def filter(event:, rack_request:)
      castle.filter(
        event: event,
        request_token: rack_request.env["action_dispatch.request.parameters"]["castle_request_token"],
        context: Castle::Context::Prepare.call(rack_request)
      )
    end

    # @param event [String]
    # @param status [String]
    # @param resource [ActiveRecord::Base]
    # @param rack_request [Rack::Request]
    def risk(event:, status:, resource:, rack_request:)
      castle.risk(
        event: event,
        status: status,
        user: {
          id: resource.castle_id,
          email: resource.email,
          registered_at: resource.created_at.utc.iso8601(3),
          traits: resource.castle_traits
        },
        request_token: rack_request.env["action_dispatch.request.parameters"]["castle_request_token"],
        context: Castle::Context::Prepare.call(rack_request)
      )
    end
  end
end