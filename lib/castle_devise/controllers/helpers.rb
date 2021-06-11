# frozen_string_literal: true

module CastleDevise
  module Controllers
    module Helpers
      def castle
        Castle::Client.new
      end
    end
  end
end
