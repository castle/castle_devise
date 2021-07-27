# frozen_string_literal: true

module CastleDevise
  # A Facade layer providing a simpler API on top of the Castle SDK
  class SdkFacade
    # @return [Castle::Client]
    attr_reader :castle

    # @param castle [Castle::Client]
    # @param before_request_hooks [Array<Proc>]
    # @param after_request_hooks [Array<Proc>]
    def initialize(castle, before_request_hooks = [], after_request_hooks = [])
      @castle = castle
      @before_request_hooks = before_request_hooks
      @after_request_hooks = after_request_hooks
    end

    # Sends request to the /v1/filter endpoint.
    # @param event [String]
    # @param context [CastleDevise::Context]
    # @return [Hash] Raw API response
    # @see https://docs.castle.io/v1/reference/api-reference/#v1filter
    def filter(event:, context:)
      payload = {
        event: event,
        user: {
          email: context.email
        },
        request_token: context.request_token,
        context: payload_context(context.rack_request)
      }

      with_request_hooks(:filter, context, payload) do
        castle.filter(payload)
      end
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

      with_request_hooks(:risk, context, payload) do
        castle.risk(payload)
      end
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
          traits: context.user_traits
        },
        context: payload_context(context.rack_request)
      }

      # registered_at field needs to be a correct value or cannot be sent out at all
      payload[:user][:registered_at] = format_time(context.registered_at) if context.registered_at
      # request_token is optional on the Log endpoint, but if it's sent it must
      # be a valid Castle token
      payload[:request_token] = context.request_token if context.request_token

      with_request_hooks(:log, context, payload) do
        castle.log(payload)
      end
    end

    private

    attr_reader :before_request_hooks, :after_request_hooks

    # @param rack_request [Rack::Request]
    # @return [Hash]
    def payload_context(rack_request)
      ctx = Castle::Context::Prepare.call(rack_request)

      # Castle SDK still generates some legacy parameters which can be removed
      # when sending requests to the new Castle endpoints
      ctx.slice!(:headers, :ip, :library)

      ctx
    end

    # @param time [Time, nil]
    # @return [String, nil]
    def format_time(time)
      time&.utc&.iso8601(3)
    end

    # @param action [Symbol] Castle API method
    # @param context [CastleDevise::Context]
    # @param payload [Hash] payload passed to the Castle Client
    def with_request_hooks(action, context, payload)
      before_request(action, context, payload)

      yield.tap do |response|
        after_request(action, context, payload, response)
      end
    end

    # @param action [Symbol] Castle API method
    # @param context [CastleDevise::Context]
    # @param payload [Hash] payload passed to the Castle Client
    def before_request(action, context, payload)
      before_request_hooks.each do |hook|
        hook.call(action, context, payload)
      end
    end

    # @param action [Symbol] Castle API method
    # @param context [CastleDevise::Context]
    # @param payload [Hash] payload passed to the Castle Client
    # @param response [Hash] response received from Castle
    def after_request(action, context, payload, response)
      after_request_hooks.each do |hook|
        hook.call(action, context, payload, response)
      end
    end
  end
end
