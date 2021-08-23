[![Gem Version](https://badge.fury.io/rb/castle_devise.svg)](https://badge.fury.io/rb/castle_devise)

**Disclaimer:** CastleDevise is currently in beta. There might be some upcoming breaking changes to the gem before we stabilize the API.

--- 

# CastleDevice

CastleDevise is a [Devise](https://github.com/heartcombo/devise) plugin that integrates [Castle](https://castle.io). 

It currently provides the following features:
- preventing bots from registration attacks using Castle's [Filter API](https://docs.castle.io/v1/reference/api-reference/#filter)
- preventing ATO attacks using Castle's [Risk API](https://docs.castle.io/v1/reference/api-reference/#risk)
- blocks attempts to update passwords for high-risk logged-in users
- logs attempts of password reset flows so that you can see them on the Castle dashboard

If you want to learn about all capabilities of Castle, please take a look at [our documentation](https://docs.castle.io/).

## Installation

Include `castle_devise` in your Gemfile:

```ruby
gem 'castle_devise'
```

Create `config/initializers/castle_devise.rb` and fill in your API secret and APP_ID from the [Castle Dashboard](https://dashboard.castle.io/settings/general)

```ruby 
CastleDevise.configure do |config|
  config.api_secret = ENV.fetch('CASTLE_API_SECRET')
  config.app_id = ENV.fetch('CASTLE_APP_ID')
  
  # When monitoring mode is enabled, CastleDevise sends
  # requests to Castle but it doesn't act on the "deny" verdicts.
  #
  # This is useful when you want to check out how Castle scores
  # your traffic without blocking any of your users.
  #
  # Once you are ready to use Castle as your security provider,
  # you can set monitoring_mode to false.
  config.monitoring_mode = true
end
```

Add `:castle_protectable` Devise module to your User model:

```ruby 
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, 
         :castle_protectable # <--- add this
end
```

Add an additional translation to your `config/locales/devise.en.yml`:

```yml
en:
  devise:
    registrations:
      blocked_by_castle: "Account cannot be created at this moment. Please try again later."
```

(See [devise.en.yml in our specs](spec/dummy_app/config/locales/devise.en.yml#L40))

#### Further steps if you're not using Webpacker

Include Castle's c.js script in the head section of your layout:

```ruby
<%= castle_javascript_tag %>
```

Add the following tag to the the `<form>` tag in both `devise/registrations/new.html.erb` and `devise/sessions/new.html.erb` (if you haven't generated them yet, run `rails generate devise:views`):

```ruby
<%= form_for @user,  html: { onsubmit: castle_on_form_submit } do |f| %>
  …
<% end %>
```

You're set! Now verify that everything works by logging in to your application as any user. You should be able to see that User on the [Castle Users Page](https://dashboard.castle.io/users)


#### Further steps if you're using Webpacker

Add `@castleio/castle-js` to your package.json file:

```
yarn add @castleio/castle-js
```

configure castle in your application pack:

```javascript
import * as Castle from '@castleio/castle-js'

Castle.configure(YOUR_APPLICATION_ID);
```

for advanced configuration follow [the readme](https://www.npmjs.com/package/@castleio/castle-js#configuration)

## How-Tos

### Customize the login flow

#### Do something after Castle denies a login

We aim to provide sensible defaults, which means that when Castle denies a login, your application
will behave as if the User has not been authenticated. You might still want to log such an event,
and you can do this in a Warden hook:

```ruby
Warden::Manager.before_failure do |env, opts|
  # The raw Castle response if a request to Castle has been made
  castle_response = env["castle_devise.risk_response"]
  # CastleDevise::Context, if a request to Castle has been made
  castle_context = env["castle_devise.risk_context"]

  if castle_response&.dig(:policy, :action) == "deny"
    # auth failed because Castle denied
  end
end

```

#### Implement your own challenge flow or do something after an "allow" action

In your `SessionsController`:

```ruby
class SessionsController < Devise::SessionsController
  def create
    super do |resource|
      if castle_challenge?
        # At this point a User is already authenticated, you might want so sign out:
        sign_out(resource)
        # .... write your own MFA flow
        # You can call #castle_risk_response to access Castle response
        # see https://docs.castle.io/v1/reference/api-reference/#risk for details

        # Fetch the Device token to use it for user feedback
        # https://docs.castle.io/v1/tutorials/advanced-features/end-user-feedback
        device_token = castle_risk_response.dig(:device, :token)

        # You might want to fetch our risk signals as well
        # https://docs.castle.io/v1/reference/signals/
        event_signals = castle_risk_response[:signals].keys
        return
      end

      # do any other action you'd like to perform after a user has been signed in below
    end
  end
end
```

Please note that some Devise extensions might completely override `Devise::SessionsController#create`.
In this case, you have to handle everything manually -  `castle_challenge?` should be called after
a call to `warden.authenticate!` has been successful.

#### Do not sent login/registration events

You can configure CastleDevise not to send login or registration events for a given Devise model:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :castle_protectable,
         castle_hooks: {
           # set it to false to prevent CastleDevise
           # from sending filter($login)
           before_registration: true,
           # set it to false to prevent CastleDevise from
           # sending risk($login) and log($login, $failed)
           after_login: true,
           # set it to false to prevent CastleDevise from
           # sending log($password_reset_request)
           after_password_reset_request: true
         }
end
```

#### Intercept request/response

You can register before- and after- request hooks in CastleDevise.

```ruby
CastleDevise.configure do |config|
  # Add custom properties to the request but only when sending
  #   requests to the Risk endpoint
  # action - Castle API endpoint (eg. :risk, :filter, :log)
  # context - CastleDevise::Context
  # payload - Hash (payload passed to the Castle SDK)
  config.before_request do |action, context, payload|
    if action == :risk
      payload[:properties] = {
        from_eu: context.resource.ip.from_eu?
      }
    end
  end

  config.before_request do |action, context, payload|
    # you can register multiple before_request hooks
  end

  # Intercept the response - enrich your logs with Castle signals
  config.after_request do |action, context, payload, response|
    Logging.add_tags(response[:signals].keys)
  end
end
```
