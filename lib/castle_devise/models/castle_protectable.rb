# frozen_string_literal: true

module Devise
  module Models
    module CastleProtectable
      extend ActiveSupport::Concern

      def castle_id
        id.to_s
      end

      def castle_traits
        {}
      end

      # This method is meant to be overridden with a human-readable username
      # that will be shown on the Castle Dashboard.
      #
      # @return [String, nil]
      def castle_name
        nil
      end
    end
  end
end
