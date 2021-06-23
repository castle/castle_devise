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
          "https://d2t77mnxyo7adj.cloudfront.net/v1/c.js?#{CastleDevise.configuration.app_id}"
        )
      end

      # Puts an inline <script> tag that includes a "castle_devise_token" field
      # within the current form.
      #
      # @example
      #   <%= form_for(resource, as: resource_name, url: sessions_path(resource_name)) do |f| %>
      #     <%= castle_request_token %>
      #     <%= f.email_field :email %>
      #     <%= f.password_field :password, autocomplete: 'off' %>
      #   <% end %>
      #
      # @return [String]
      def castle_request_token
        tag = <<~HEREDOC
          <script>
          // The current script tag is the last one at the time of load
          var el = document.getElementsByTagName('script');
          el = el[el.length - 1];

          // Traverse up until we find a form
          while (el  && el !== document) {
            if (el.tagName === 'FORM') break;
            el = el.parentNode;
          }

          // Intercept the form submit
          if (el.tagName === 'FORM') {
            el.onsubmit = function(e) {
              e.preventDefault();

              _castle('createRequestToken').then(function(requestToken) {
                // Populate a hidden field called `castle_request_token` with the
                // request token
                var hiddenInput = document.createElement('input');
                hiddenInput.setAttribute('type', 'hidden');
                hiddenInput.setAttribute('name', 'castle_request_token');
                hiddenInput.setAttribute('value', requestToken);

                // Add the hidden field to the form so it gets sent to the server
                // before submitting the form
                el.appendChild(hiddenInput);

                el.submit();
              });
            };
          } else {
            console.log('[Castle] The script helper needs to be within a <form> tag')
          }
          </script>
        HEREDOC
        tag.html_safe
      end
    end
  end
end
