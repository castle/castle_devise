# frozen_string_literal: true

RSpec.describe CastleDevise::SdkFacade do
  subject(:facade) { CastleDevise::SdkFacade.new(Castle::Client.new) }

  let(:event) { "$registration" }
  let(:rack_params) do
    {
      "user" => {"email" => "user@example.com", "password" => "password"},
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
        email: "user@example.com",
        password: "123456",
        password_confirmation: "123456"
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
                token: String
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
