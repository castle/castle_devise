# frozen_string_literal: true

require "logger"

module CastleDevise
  # Configuration object
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

    # @!attribute logger
    #   @return [Logger] A Logger instance. You might want to use Rails.logger here.
    attr_accessor :logger

    # @!attribute before_request_hooks
    #   @return [Array<Proc>] Array of procs that will get called before a request to the Castle API
    attr_accessor :before_request_hooks

    # @!attribute after_request_hooks
    #   @return [Array<Proc>] Array of procs that will get called after a request to the Castle API
    attr_accessor :after_request_hooks

    # @!attribute castle_sdk_facade_class
    #   @return [Class] Castle API implementation
    attr_accessor :castle_sdk_facade_class

    # @!attribute castle_client
    #   @return [Class] Castle SDK client
    attr_accessor :castle_client

    def initialize
      @monitoring_mode = false
      @logger = Logger.new("/dev/null")
      @before_request_hooks = []
      @after_request_hooks = []
      @castle_sdk_facade_class = ::CastleDevise::SdkFacade
      @castle_client = ::Castle::Client.new
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
