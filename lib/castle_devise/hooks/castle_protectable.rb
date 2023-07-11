# frozen_string_literal: true

Warden::Manager.after_authentication do |resource, warden, opts|
  next unless resource.devise_modules.include?(:castle_protectable)
  next unless resource.class.castle_hooks[:after_login]

  context = CastleDevise::Context.from_rack_env(warden.env, opts[:scope], resource)

  warden.env["castle_devise.risk_context"] = context

  begin
    response = CastleDevise.sdk_facade.risk(
      event: "$login",
      context: context
    )

    warden.env["castle_devise.risk_response"] = response

    next if CastleDevise.monitoring_mode?

    if response.dig(:policy, :action) == "deny"
      # high ATO risk, pretend the User does not exist
      context.logout!
    end
  rescue Castle::InvalidParametersError
    # log API error and allow
    CastleDevise.logger.warn(
      "[CastleDevise] /v1/risk request contained invalid parameters."
    )
  rescue Castle::InvalidRequestTokenError
    CastleDevise.logger.warn(
      "[CastleDevise] /v1/risk request contained invalid parameters." \
      " This might mean that either you didn't configure Castle's Javascript properly, or" \
      " a request has been made without Javascript (eg. cURL/bot)." \
      " Such a request is treated as if Castle responded with a 'deny' action in non-monitoring mode."
    )

    context.logout! unless CastleDevise.monitoring_mode?
  rescue Castle::Error => e
    # log API errors and allow
    CastleDevise.logger.error("[CastleDevise] risk($login): #{e}")
  end
end

Warden::Manager.before_failure do |env, opts|
  next if opts[:castle_devise] == :skip
  # recall is set by Devise on a failed login attempt. If it's not set, this hook might fire on any
  # authentication failure attempt (eg. trying to access a resource while unauthenticated), not just login specifically
  next unless opts.key?(:recall)

  resource_class = Devise.mappings[opts[:scope]].to

  next if resource_class.nil?
  next unless resource_class.devise_modules.include?(:castle_protectable)
  next unless resource_class.castle_hooks[:after_login]

  context = CastleDevise::Context.from_rack_env(env, opts[:scope])

  begin
    CastleDevise.sdk_facade.filter(
      event: "$login",
      status: "$failed",
      context: context
    )
  rescue Castle::Error => e
    CastleDevise.logger.error("[CastleDevise] filter($login, $failed): #{e}")
  end
end
