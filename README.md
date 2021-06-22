# CastleDevice

CastleDevise is a [Devise](https://github.com/heartcombo/devise) plugin that integrates [Castle](https://castle.io). 

It currently provides the following features:
- preventing bots from registration attacks using Castle's [Filter API](https://docs.castle.io/v1/reference/api-reference/#filter)
- preventing ATO attacks using Castle's [Risk API](https://docs.castle.io/v1/reference/api-reference/#risk)

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

#### Further steps if you're not using Webpacker

Include Castle's c.js script in the head section of your layout:

```ruby
<%= castle_javascript_tag %>
```

Add the following tag to the the `<form>` tag in both `devise/registrations/new.html.erb` and `devise/sessions/new.html.erb` (if you haven't generated them yet, run `rails generate devise:views`):

```ruby
<%= form_for @user do |f| %>
  …
  <%= castle_request_token %>
  …
<% end %>
```

You're set! Now verify that everything works by logging in to your application as any user. You should be able to see that User on the [Castle Users Page](https://dashboard.castle.io/users)


#### Further steps if you're using Webpacker

Add `castle.js` to your package.json file.

TODO: fill this in.


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
