# frozen_string_literal: true

RSpec.describe "Logging in", type: :request do
  let!(:user) do
    User.create!(
      email: "user@example.com",
      password: "123456",
      password_confirmation: "123456"
    )
  end

  let(:facade) { instance_double(CastleDevise::SdkFacade) }

  let(:castle_risk_response) do
    {
      risk: 0.4,
      signals: {},
      policy: {
        action: policy_action,
        name: "My Policy",
        id: "e14c5a8d-c682-4a22-bbca-04fa6b98ad0c",
        revision_id: "b5cf794e-88c0-426e-8276-037ba1e7ceca"
      },
      device: {
        token: "eyJhbGciOiJIUzI1NiJ9.eyJ0b2tlbiI6IlQyQ"
      }
    }
  end
  let(:policy_action) { "allow" }

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
    allow(facade).to receive(:risk).and_return(castle_risk_response)
  end

  context "with non-existing user" do
    before do
      allow(facade).to receive(:log)

      post "/users/sign_in",
        params: {
          user: {email: "non-existing@example.com", password: "123456"},
          castle_request_token: "token123"
        }
    end

    it "logs the event" do
      expect(facade).to have_received(:log) do |event:, status:, context:|
        expect(event).to eq("$login")
        expect(status).to eq("$failed")
        expect(context.email).to eq("non-existing@example.com")
      end
    end
  end

  context "with incorrect password" do
    before do
      allow(facade).to receive(:log)

      post "/users/sign_in",
        params: {
          user: {email: user.email, password: "333"},
          castle_request_token: "token123"
        }
    end

    it "logs the event" do
      expect(facade).to have_received(:log) do |event:, status:, context:|
        expect(event).to eq("$login")
        expect(status).to eq("$failed")
        expect(context.email).to eq(user.email)
      end
    end
  end

  context "with correct password" do
    before do
      post "/users/sign_in",
        params: {
          user: {email: user.email, password: "123456"},
          castle_request_token: "token123"
        }
    end

    context "when Castle returns an allow verdict" do
      let(:policy_action) { "allow" }

      it "calls the facade with valid arguments" do
        expect(facade).to have_received(:risk) do |event:, context:|
          expect(event).to eq("$login")
          expect(context).to be_a(CastleDevise::Context)
          expect(context.resource).to eq(user)
        end
      end

      it "authenticates the user" do
        expect(request.env["warden"].user(:user)).to eq(user)
      end
    end

    context "when Castle return a challenge verdict" do
      let(:policy_action) { "challenge" }

      it "calls the facade with valid arguments" do
        expect(facade).to have_received(:risk) do |event:, context:|
          expect(event).to eq("$login")
          expect(context).to be_a(CastleDevise::Context)
          expect(context.resource).to eq(user)
        end
      end

      xit "challenges the user" do
      end
    end

    context "when Castle returns a deny verdict" do
      let(:policy_action) { "deny" }

      it "calls the facade with valid arguments" do
        expect(facade).to have_received(:risk) do |event:, context:|
          expect(event).to eq("$login")
          expect(context).to be_a(CastleDevise::Context)
          expect(context.resource).to eq(user)
        end
      end

      it "does not authenticate the user" do
        expect(request.env["warden"].user(:user)).to be_nil
      end

      it "sets a flash message" do
        expect(flash.alert).to match(/invalid email or password/i)
      end
    end
  end
end
