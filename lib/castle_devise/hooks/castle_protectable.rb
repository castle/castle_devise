# frozen_string_literal: true

Warden::Manager.after_authentication do |resource, warden, opts|
  next unless resource.devise_modules.include?(:castle_protectable)

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

Warden::Manager.before_failure do |env, opts|
  next if opts[:castle_devise] == :skip

  resource_class = Devise.mappings[opts[:scope]]

  next if resource_class.nil?
  next unless resource_class.modules.include?(:castle_protectable)

  context = CastleDevise::Context.from_rack_env(env, opts[:scope])

  begin
    CastleDevise.sdk_facade.log(
      event: "$login",
      status: "$failed",
      context: context
    )
  rescue Castle::Error => e
    CastleDevise.logger.info e
  end
end
