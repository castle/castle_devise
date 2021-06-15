# frozen_string_literal: true

Warden::Manager.after_authentication do |resource, warden, opts|
  next unless resource.respond_to?(:castle_id)

  context = CastleDevise::Context.from_warden(warden, resource, opts[:scope])

  begin
    response = CastleDevise.sdk_facade.risk(
      event: "$login",
      context: context
    )
    case response.dig(:policy, :action)
    when "deny"
      # high ATO risk, pretend the User does not exist
      context.logout!
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
