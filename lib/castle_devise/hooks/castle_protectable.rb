# frozen_string_literal: true

Warden::Manager.after_authentication do |resource, warden, opts|
  next unless resource.respond_to?(:castle_id)

  begin
    response = CastleDevise.sdk_facade.risk(
      event: "$login",
      resource: resource,
      rack_request: Rack::Request.new(warden.env)
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
