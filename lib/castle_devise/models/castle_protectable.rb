# frozen_string_literal: true

module Devise
  module Models
    # This module contains methods that will be included in your Devise model when you
    # include the castle_protectable Devise module.
    #
    # Configuration:
    #
    #   castle_hooks: configures which events trigger Castle API calls
    #     {
    #       after_login: true, # trigger risk($login) and log($login, $failed),
    #       before_registration: true # trigger filter($registration)
    #     }
    module CastleProtectable
      extend ActiveSupport::Concern

      module ClassMethods
        Devise::Models.config(self, :castle_hooks)
      end

      # @return [String, nil] ID used for sending requests to Castle
      def castle_id
        id&.to_s
      end

      # @return [Hash] additional traits that will be sent to Castle
      #
      # @example
      # @example
      #   class User
      #     belongs_to :company
      #
      #     devise :castle_protectable,
      #            :confirmable,
      #            :database_authenticatable,
      #            :registerable,
      #            :rememberable,
      #            :validatable
      #
      #     def castle_traits
      #       {
      #         company_name: company.name
      #       }
      #     end
      #   end
      def castle_traits
        {}
      end

      # This method is meant to be overridden with a human-readable username
      # that will be shown on the Castle Dashboard.
      #
      # @return [String, nil]
      #
      # @example
      #   class User
      #     devise :castle_protectable,
      #            :confirmable,
      #            :database_authenticatable,
      #            :registerable,
      #            :rememberable,
      #            :validatable
      #
      #     def castle_name
      #       [first_name, last_name].join(' ').strip
      #     end
      #   end
      def castle_name
        nil
      end
    end
  end
end
