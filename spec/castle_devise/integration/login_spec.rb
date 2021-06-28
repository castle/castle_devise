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
  let(:castle_risk_response) { allow_risk_response }

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
      let(:castle_risk_response) { allow_risk_response }

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

      it "stores context and response in Rack env" do
        expect(request.env["castle_devise.risk_response"]).to eq(castle_risk_response)
        expect(request.env["castle_devise.risk_context"]).to be_a(CastleDevise::Context)
      end
    end

    context "when Castle return a challenge verdict" do
      let(:castle_risk_response) { challenge_risk_response }

      it "calls the facade with valid arguments" do
        expect(facade).to have_received(:risk) do |event:, context:|
          expect(event).to eq("$login")
          expect(context).to be_a(CastleDevise::Context)
          expect(context.resource).to eq(user)
        end
      end

      it "stores context and response in Rack env" do
        expect(request.env["castle_devise.risk_response"]).to eq(castle_risk_response)
        expect(request.env["castle_devise.risk_context"]).to be_a(CastleDevise::Context)
      end
    end

    context "when Castle returns a deny verdict" do
      let(:castle_risk_response) { deny_risk_response }

      context "and monitoring mode is enabled" do
        around do |example|
          CastleDevise.configuration.monitoring_mode = true
          example.run
          CastleDevise.configuration.monitoring_mode = false
        end

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

        it "stores context and response in Rack env" do
          expect(request.env["castle_devise.risk_response"]).to eq(castle_risk_response)
          expect(request.env["castle_devise.risk_context"]).to be_a(CastleDevise::Context)
        end
      end

      context "and monitoring mode is disabled" do
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

        it "stores context and response in Rack env" do
          expect(request.env["castle_devise.risk_response"]).to eq(castle_risk_response)
          expect(request.env["castle_devise.risk_context"]).to be_a(CastleDevise::Context)
        end
      end
    end
  end
end
