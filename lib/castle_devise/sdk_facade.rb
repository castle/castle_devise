# frozen_string_literal: true

module CastleDevise
  # A Facade layer providing a simpler API on top of the Castle SDK
  class SdkFacade
    # @return [Castle::Client]
    attr_reader :castle

    # @param castle [Castle::Client]
    def initialize(castle)
      @castle = castle
    end

    # Sends request to the /v1/filter endpoint.
    # @param event [String]
    # @param context [CastleDevise::Context]
    # @return [Hash] Raw API response
    # @see https://docs.castle.io/v1/reference/api-reference/#v1filter
    def filter(event:, context:)
      castle.filter(
        event: event,
        user: {
          email: context.email
        },
        request_token: context.request_token,
        context: payload_context(context.rack_request)
      )
    end

    # Sends request to the /v1/risk endpoint.
    # @param event [String]
    # @param context [CastleDevise::Context]
    # @return [Hash] Raw API response
    # @see https://docs.castle.io/v1/reference/api-reference/#v1risk
    def risk(event:, context:)
      payload = {
        event: event,
        status: "$succeeded",
        user: {
          id: context.castle_id,
          email: context.email,
          registered_at: format_time(context.registered_at),
          traits: context.user_traits
        },
        request_token: context.request_token,
        context: payload_context(context.rack_request)
      }

      payload[:user][:name] = context.username if context.username

      castle.risk(payload)
    end

    # Sends request to the /v1/log endpoint.
    # @param event [String]
    # @param status [String, nil]
    # @param context [CastleDevise::Context]
    # @return [Hash] Raw API response
    # @see https://docs.castle.io/v1/reference/api-reference/#v1log
    def log(event:, status:, context:)
      payload = {
        event: event,
        status: status,
        user: {
          id: context.castle_id,
          email: context.email,
          registered_at: format_time(context.registered_at),
          traits: context.user_traits
        }.compact,
        request_token: context.request_token,
        context: payload_context(context.rack_request)
      }

      castle.log(payload)
    end

    private

    # @param rack_request [Rack::Request]
    # @return [Hash]
    def payload_context(rack_request)
      ctx = Castle::Context::Prepare.call(rack_request)

      ctx.slice!(:headers, :ip, :library)

      ctx[:library][:name] += "; CastleDevise"
      ctx[:library][:version] += "; #{CastleDevise::VERSION}"

      ctx
    end

    # @param time [Time, nil]
    # @return [String, nil]
    def format_time(time)
      time&.utc&.iso8601(3)
    end
  end
end
