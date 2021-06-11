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
    end
  end
end
