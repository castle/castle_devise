# frozen_string_literal: true

module Devise
  module Models
    module CastleProtectable
      extend ActiveSupport::Concern

      # User ID that will be sent to Castle. In most cases it is the same as the model's ID,
      # unless:
      # - you have some sort of composite ID key
      # - you have multiple Devise models that might have overlapping IDs. In this case you might
      #     want to prefix `castle_id` with the model name, eg "user-123" and "admin-123"
      #
      # @return [String]
      def castle_id
        id.to_s
      end

      # User traits that will be sent to Castle. You can override this method
      # with any additional data you might want to see in the Castle dashboard.
      #
      # @return [Hash]
      def castle_traits
        {}
      end
    end
  end
end
