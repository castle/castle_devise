# frozen_string_literal: true

module RequestsHelper
  # @param email [String]
  # @param password [String]
  # @param request_token [String]
  def send_sign_in_request(email, password, request_token)
    post "/users/sign_in",
      params: {
        user: {
          email: email,
          password: password
        },
        castle_request_token: request_token
      }
  end
end
