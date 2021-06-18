# frozen_string_literal: true

module CastleDevise
  # Provides a small layer of abstraction on top of raw Rack::Request and Warden
  class Context
    class << self
      # @param warden [Warden::Proxy]
      # @param resource [ActiveRecord::Base]
      # @param scope [Symbol]
      # @return [CastleDevise::Context]
      def from_warden(warden, resource, scope)
        new(
          rack_request: Rack::Request.new(warden.env),
          resource: resource,
          scope: scope
        )
      end

      # @param rack_env [Hash]
      # @return [CastleDevise::Context]
      def from_rack_env(rack_env, resource = nil, scope = nil)
        new(
          rack_request: Rack::Request.new(rack_env),
          resource: resource,
          scope: scope
        )
      end
    end

    attr_reader :rack_request, :resource, :scope

    # @param rack_request [Rack::Request]
    # @param resource [ActiveRecord::Base]
    # @param scope [Symbol] Warden scope
    def initialize(rack_request:, resource: nil, scope: nil)
      @rack_request = rack_request
      @resource = resource
      @scope = scope
    end

    # @return [String, nil] Castle request token, if present in POST params
    def request_token
      rack_request.env["rack.request.form_hash"]["castle_request_token"]
    end

    # @return [String, nil]
    def castle_id
      resource&.castle_id
    end

    # @return [String, nil]
    def email
      resource&.email
    end

    # @return [Hash]
    def user_traits
      resource&.castle_traits || {}
    end

    # @return [Time, nil]
    def registered_at
      resource&.created_at
    end

    # Logs out current resource
    def logout!
      warden.logout(scope)
      throw(:warden, scope: scope, message: :not_found_in_database)
    end

    private

    # @return [Warden::Proxy]
    def warden
      rack_request.env["warden"]
    end
  end
end
