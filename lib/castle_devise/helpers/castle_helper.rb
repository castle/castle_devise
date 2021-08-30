# frozen_string_literal: true

module CastleDevise
  module Helpers
    # Methods defined here will be available in all your views.
    module CastleHelper
      # Creates a <script> tag that includes our c.js script from a CDN.
      # You have to make sure that your app_id is valid, otherwise the script won't work.
      #
      # You shouldn't call this method if you bundle our c.js script with your other
      # JS packages.
      #
      # You should put this in the <head> section of your page:
      #
      # @example
      #   # app/views/layouts/application.html.erb
      #   <!DOCTYPE html>
      #   <html>
      #   <head>
      #     <%= castle_javascript_tag %>
      #   <title>Your app title</title>
      #
      #   <!-- the rest of your layout -->
      def castle_javascript_tag
        javascript_include_tag(
          "https://cdn.castle.io/v2/castle.js?#{CastleDevise.configuration.app_id}"
        )
      end

      # Puts an inline <script> tag that includes a "castle_devise_token" field
      # within the current form.
      #
      # @example
      #   <%= form_for(resource, as: resource_name, url: sessions_path(resource_name), html: { onsubmit: castle_on_form_submit }) do |f| %>
      #     <%= f.email_field :email %>
      #     <%= f.password_field :password, autocomplete: 'off' %>
      #   <% end %>
      #
      # @return [String]
      def castle_on_form_submit
        "typeof(_castle)=='undefined'?event.preventDefault():_castle('onFormSubmit', event)"
      end
    end
  end
end
