# frozen_string_literal: true

module CastleDevise
  module Helpers
    # Methods defined here will be available in all your views.
    module CastleHelper
      BOOTSTRAP_JS = File.read(File.expand_path("castle_devise.js", __dir__)).freeze
      # 3.x UMD is named @castleio/castle-js, so seed module.exports as window.Castle before the script tag.
      UMD_SHIM = <<~JS
        if (!window.Castle) {
          window.exports = window.exports || {};
          window.module = window.module || { exports: window.exports };
          window.Castle = window.module.exports;
        }
      JS

      # Configures the Castle browser SDK with { pk: }. Pass src: to also load a
      # hosted UMD build; omit it when the host app already imported the npm module.
      #
      # @param src [String, nil] URL or path of castle.umd.js (keep workers in the same directory)
      # @return [String]
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
      def castle_javascript_tag(src: nil)
        parts = []
        if src
          parts << javascript_tag(UMD_SHIM)
          parts << javascript_include_tag(src)
        end
        parts << javascript_tag(castle_js_bootstrap)
        safe_join(parts)
      end

      # onsubmit handler that mints castle_request_token via 2.x injectTokenOnSubmit
      # or 2.x/3.x createRequestToken.
      #
      # @example
      #   <%= form_for(resource, as: resource_name, url: sessions_path(resource_name), html: { onsubmit: castle_on_form_submit }) do |f| %>
      #     <%= f.email_field :email %>
      #     <%= f.password_field :password, autocomplete: 'off' %>
      #   <% end %>
      #
      # @return [String]
      def castle_on_form_submit
        "castleDeviseOnFormSubmit(event)"
      end

      private

      def castle_js_bootstrap
        BOOTSTRAP_JS.sub("__CASTLE_DEVISE_PK__", CastleDevise.configuration.publishable_key.to_json)
      end
    end
  end
end
