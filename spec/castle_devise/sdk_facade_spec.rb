# frozen_string_literal: true

RSpec.describe CastleDevise::SdkFacade do
  subject(:facade) { CastleDevise::SdkFacade.new(castle, before_hooks, after_hooks) }

  let(:user_email) { "user@example.com" }
  let(:user_password) { "password" }
  let(:user_rack_params) { {"email" => user_email, "password" => user_password} }
  let(:rack_params) do
    {
      "user" => user_rack_params,
      "castle_request_token" => "3NzgMvRonsQ1mlt9SkqSBChy4807pQTeC5dpzRySB6Ml0CDTWLDozQ03Z0olj1fFNoMlNQzYZj7HBg2aC4-fMbjIarJs7i-icv4OoWm4V-M4t0qAafQLo3z4EaUztyujfPIO7UX2Ae1HxEKVKKZSkjmiPfohtyO9ePsHmm31KaR8uFf-P7lR-yi_KYVc2i7hKPsLpm23Jahr_A3kKNQKv2f6B-Ixpkz9JqNW-jq5U_w8tzGsbvYQpCeiUfompFShAPFX9Gv2V_Q54GHOg5f2xTDzBvhtr1b7lLQro3zyDuVavkKEev4R5VzaS-1Y-xe-KNAQrHj_C657t1T4PTN2_Tm4Uvwnplv6OLtC_TmtUv0yp1ItCP9iYrqXYs0Il2LNCCXEZpQw82edLSJ3SNdijUiXYs0IORpjcDMavwjlYrlZP8qxdNNiUaDnZsIIl23NCJZiMg"
    }
  end
  let(:request) do
    Rack::Request.new(
      Rack::MockRequest.env_for(
        "/users",
        :method => "POST",
        "rack.request.form_hash" => rack_params,
        "REMOTE_ADDR" => "1.2.3.4"
      )
    )
  end
  let(:context) { CastleDevise::Context.from_rack_env(request.env, :user) }

  shared_examples "calls before- and after- hooks" do |method|
    let(:castle) { instance_double(Castle::Client, method => castle_response) }
    let(:before_hook) do
      ->(action, context, payload) do
        payload[:test] = 1
      end
    end
    let(:castle_response) { double }
    let(:before_spy) { spy }
    let(:after_spy) { spy }
    let(:before_hooks) { [before_spy, before_hook] }
    let(:after_hooks) { [after_spy] }

    it "calls before_hooks" do
      expect(before_spy).to have_received(:call).with(method, context, Hash)
    end

    it "before_hook can modify the payload" do
      expect(castle).to have_received(method).with(hash_including(test: 1))
    end

    it "calls after_hooks" do
      expect(after_spy).to have_received(:call)
        .with(method, context, Hash, castle_response)
    end
  end

  describe "#filter" do
    let(:event) { "$login" }

    include_examples "calls before- and after- hooks", :filter do
      before do
        facade.filter(event: event, context: context)
      end
    end
  end

  describe "#risk" do
    let(:event) { "$login" }

    include_examples "calls before- and after- hooks", :risk do
      before do
        facade.risk(event: event, context: context)
      end
    end
  end

  describe "#log" do
    let(:event) { "$login" }

    include_examples "calls before- and after- hooks", :log do
      before do
        facade.log(event: event, status: "$failed", context: context)
      end
    end

    describe "user's params" do
      context "when user given as resource" do
        let!(:user) do
          User.create!(
            email: user_email,
            password: user_password,
            password_confirmation: user_password
          )
        end
        let(:context) { CastleDevise::Context.from_rack_env(request.env, :user, user) }
        let(:user_rack_params) { {} }
        let(:expected_user_params) do
          {
            email: user_email,
            id: user.id.to_s,
            registered_at: user.created_at.utc.iso8601(3),
            traits: {}
          }
        end

        it "performs the request to log with all the user's attributes" do
          expect(castle).to have_received(:log).with(
            hash_including(user: expected_user_params)
          )
        end
      end

      context "when user given as rack request params and email is present" do
        let(:expected_user_params) do
          {
            email: user_email
          }
        end

        it "performs the request to log with user's email only" do
          expect(castle).to have_received(:log).with(
            hash_including(user: expected_user_params)
          )
        end
      end

      context "when user given as rack request params and email is not present" do
        let(:user_email) { nil }

        it "does not perform the request to log" do
          expect(castle).not_to have_received(:log)
        end
      end
    end
  end

  context "VCR specs" do
    let(:castle) { Castle::Client.new }
    let(:before_hooks) { [] }
    let(:after_hooks) { [] }
    let(:event) { "$registration" }

    describe "#filter" do
      it "matches the API contract" do
        VCR.use_cassette("castle_filter_api") do
          response = facade.filter(event: event, context: context)

          expect(response).to(
            match(
              hash_including(
                risk: Float,
                signals: Hash,
                policy: {
                  action: String,
                  id: String,
                  revision_id: String,
                  name: String
                }
              )
            )
          )
        end
      end
    end

    describe "#risk" do
      let(:user) do
        User.create!(
          email: user_email,
          password: user_password,
          password_confirmation: user_password
        )
      end

      let(:context) { CastleDevise::Context.from_rack_env(request.env, :user, user) }

      it "matches the API contract" do
        VCR.use_cassette("castle_risk_api") do
          response = facade.risk(event: event, context: context)

          expect(response).to(
            match(
              hash_including(
                risk: Float,
                signals: Hash,
                policy: {
                  action: String,
                  id: String,
                  revision_id: String,
                  name: String
                },
                device: {
                  token: String,
                  fingerprint: String
                }
              )
            )
          )
        end
      end
    end

    describe "#log" do
      it "matches the API contract" do
        VCR.use_cassette("castle_log_api") do
          response = facade.log(event: event, status: "$failed", context: context)

          # Response is empty & successful, these 2 fields come from the SDK
          # meaning that there was no error and no failover action
          expect(response).to eq(failover: false, failover_reason: nil)
        end
      end
    end
  end
end
