# frozen_string_literal: true

Warden::Manager.after_authentication do |record, warden, opts|
  next unless record.respond_to?(:castle_id)

  castle = Castle::Client.new
  begin
    response = castle.risk(
      event: "$login",
      status: "$succeeded",
      user: {
        id: record.castle_id,
        email: record.email,
        registered_at: record.created_at.utc.iso8601(3),
        traits: record.castle_traits || {}
      },
      request_token: warden.env["action_dispatch.request.parameters"]["castle_request_token"],
      context: Castle::Context::Prepare.call(Rack::Request.new(warden.env))
    )

    case response.dig(:policy, :action)
    when "deny"
      # high ATO risk, pretend the User does not exist
      warden.logout(opts[:scope])
      throw(:warden, scope: opts[:scope], message: :not_found_in_database)
    when "challenge"
      # You might implement an MFA challenge flow here
    else
      # everything fine, continue
    end
  rescue Castle::Error => e
    # log API errors and allow
    CastleDevise.logger.info e
  end
end
