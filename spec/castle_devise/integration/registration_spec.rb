# frozen_string_literal: true

RSpec.describe "Registration attempt", type: :request do
  let(:facade) { instance_double(CastleDevise::SdkFacade) }

  def send_registration_request
    post "/users",
      params: {
        user: {email: "user@example.com", password: "123456", password_confirmation: "123456"},
        castle_request_token: "token123"
      }
  end

  let(:castle_response) do
    {
      risk: 0.4,
      signals: {},
      policy: {
        action: policy_action,
        name: "My Policy",
        id: "e14c5a8d-c682-4a22-bbca-04fa6b98ad0c",
        revision_id: "b5cf794e-88c0-426e-8276-037ba1e7ceca"
      }
    }
  end
  let(:policy_action) { "allow" }

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
    allow(facade).to receive(:filter).and_return(castle_response)
  end

  context "when Castle returns an allow verdict" do
    let(:policy_action) { "allow" }

    before { send_registration_request }

    it "sends requests to Castle" do
      expect(facade).to have_received(:filter) do |event:, context:|
        expect(event).to eq("$registration")
        expect(context.email).to eq("user@example.com")
        expect(context.request_token).to eq("token123")
      end
    end

    it "creates a user" do
      expect(request.env["warden"].user(:user)).to be_persisted
    end
  end

  context "when Castle returns a challenge" do
    let(:policy_action) { "challenge" }

    before { send_registration_request }

    it "sends requests to Castle" do
      expect(facade).to have_received(:filter) do |event:, context:|
        expect(event).to eq("$registration")
        expect(context.email).to eq("user@example.com")
        expect(context.request_token).to eq("token123")
      end
    end
  end

  context "when Castle returns a deny verdict" do
    let(:policy_action) { "deny" }

    context "and monitoring mode is enabled" do
      before { send_registration_request }

      around do |example|
        CastleDevise.configuration.monitoring_mode = true
        example.run
        CastleDevise.configuration.monitoring_mode = false
      end

      it "sends requests to Castle" do
        expect(facade).to have_received(:filter) do |event:, context:|
          expect(event).to eq("$registration")
          expect(context.email).to eq("user@example.com")
          expect(context.request_token).to eq("token123")
        end
      end

      it "creates a user" do
        expect(request.env["warden"].user(:user)).to be_persisted
      end
    end

    context "and monitoring mode is disabled" do
      before { send_registration_request }

      it "sends requests to Castle" do
        expect(facade).to have_received(:filter) do |event:, context:|
          expect(event).to eq("$registration")
          expect(context.email).to eq("user@example.com")
          expect(context.request_token).to eq("token123")
        end
      end

      it "does not create a user" do
        expect(request.env["warden"].user(:user)).to be_nil
      end

      it "sets a flash message" do
        expect(flash.alert).to match(/account cannot be created/i)
      end

      it "redirects to the login page" do
        expect(response).to redirect_to("/users/sign_in")
      end
    end
  end

  context "when Castle raises InvalidParametersError" do
    before do
      allow(facade).to receive(:filter).and_raise(Castle::InvalidParametersError)
      send_registration_request
    end

    context "and monitoring mode is enabled" do
      around do |example|
        CastleDevise.configuration.monitoring_mode = true
        example.run
        CastleDevise.configuration.monitoring_mode = false
      end

      it "creates a user" do
        expect(request.env["warden"].user(:user)).to be_persisted
      end
    end

    context "and monitoring mode is disabled" do
      it "does not create a user" do
        expect(request.env["warden"].user(:user)).to be_nil
      end

      it "sets a flash message" do
        expect(flash.alert).to match(/account cannot be created/i)
      end

      it "redirects to the login page" do
        expect(response).to redirect_to("/users/sign_in")
      end
    end
  end

  context "when Castle raises a different error" do
    before do
      allow(facade).to receive(:filter).and_raise(Castle::Error)
      allow(CastleDevise.logger).to receive(:error)
      send_registration_request
    end

    it "logs the error" do
      expect(CastleDevise.logger).to have_received(:error)
    end

    it "creates a user" do
      expect(request.env["warden"].user(:user)).to be_persisted
    end
  end
end
