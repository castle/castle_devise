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

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
  end

  context "when registration hooks are disabled" do
    around do |example|
      User.castle_hooks[:before_registration] = false
      example.run
      User.castle_hooks[:before_registration] = true
    end

    before do
      allow(facade).to receive(:filter)
      send_registration_request
    end

    it "does not send a request to Castle" do
      expect(facade).not_to have_received(:filter)
    end

    it "creates a user" do
      expect(request.env["warden"].user(:user)).to be_persisted
    end
  end

  context "when Castle returns an allow verdict" do
    let(:castle_response) { allow_filter_response }

    before do
      allow(facade).to receive(:filter).and_return(castle_response)
      send_registration_request
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

  describe "when Castle returns a deny verdict" do
    let(:castle_response) { deny_filter_response }

    context "and monitoring mode is enabled" do
      before do
        allow(facade).to receive(:filter).and_return(castle_response)
        send_registration_request
      end

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
      before do
        allow(facade).to receive(:filter).and_return(castle_response)
        send_registration_request
      end

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
