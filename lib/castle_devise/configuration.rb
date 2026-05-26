# frozen_string_literal: true

require "logger"

module CastleDevise
  # Plain Ruby configuration object for CastleDevise.
  #
  # Previously this used +ActiveSupport::Configurable+, which is deprecated
  # and slated for removal in Rails 8.2.
  class Configuration
    # @!attribute api_secret
    #   @return [String] Your API secret
    attr_accessor :api_secret

    # @!attribute app_id
    #   @return [String] Your Castle App ID
    attr_accessor :app_id

    # @!attribute monitoring_mode
    #   When CastleDevise is in monitoring mode, it sends requests to Castle
    #   but it doesn't act on "deny" verdicts.
    #
    #   This mode is useful if you're just checking Castle out and you're not yet sure whether
    #   your configuration is correct so you don't accidentally block legitimate users
    #   from logging in/registering.
    #
    #   @return [true, false] whether to act on deny requests or not
    attr_accessor :monitoring_mode

    # @!attribute before_request_hooks
    #   @return [Array<Proc>] Array of procs that will get called before a request to the Castle API
    attr_accessor :before_request_hooks

    # @!attribute after_request_hooks
    #   @return [Array<Proc>] Array of procs that will get called after a request to the Castle API
    attr_accessor :after_request_hooks

    attr_writer :logger, :castle_sdk_facade_class, :castle_client

    def initialize
      @monitoring_mode = false
      @before_request_hooks = []
      @after_request_hooks = []
    end

    # @!attribute logger
    #   @return [Logger] A Logger instance. You might want to use Rails.logger here.
    def logger
      @logger ||= Logger.new(File::NULL)
    end

    # @!attribute castle_sdk_facade_class
    #   @return [Class] Castle API implementation
    def castle_sdk_facade_class
      @castle_sdk_facade_class ||= ::CastleDevise::SdkFacade
    end

    # @!attribute castle_client
    #   @return [Castle::Client] Castle SDK client
    def castle_client
      @castle_client ||= ::Castle::Client.new
    end

    # Adds a new before_request hook
    # @param blk [Proc]
    def before_request(&blk)
      before_request_hooks << blk
    end

    # Adds a new after_request hook
    # @param blk [Proc]
    def after_request(&blk)
      after_request_hooks << blk
    end
  end
end
