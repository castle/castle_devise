# frozen_string_literal: true

RSpec.describe "Registration attempt", type: :request do
  let(:facade) { instance_double(CastleDevise::SdkFacade) }

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
    allow(facade).to receive(:filter).and_return(castle_response)

    post "/users",
      params: {
        user: {email: "user@example.com", password: "123456", password_confirmation: "123456"},
        castle_request_token: "token123"
      }
  end

  describe "when Castle returns an allow verdict" do
    let(:castle_response) { allow_filter_response }

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
end
