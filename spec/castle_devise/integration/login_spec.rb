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

  def send_sign_in_request(email, password, request_token)
    post "/users/sign_in",
      params: {
        user: {email: email, password: password},
        castle_request_token: request_token
      }
  end

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
    allow(facade).to receive(:risk).and_return(castle_risk_response)
  end

  context "with non-existing user" do
    before do
      allow(facade).to receive(:log)

      send_sign_in_request("non-existing@example.com", "123456", "token123")
    end

    it "logs the event" do
      expect(facade).to have_received(:log) do |event:, status:, context:|
        expect(event).to eq("$login")
        expect(status).to eq("$failed")
        expect(context.email).to eq("non-existing@example.com")
      end
    end

    it "is successful" do
      expect(response).to be_successful
    end

    it "contains proper flash message" do
      expect(flash.alert).to match(/invalid email or password/i)
    end
  end

  context "with incorrect password" do
    before do
      allow(facade).to receive(:log)

      send_sign_in_request(user.email, "333", "token123")
    end

    it "logs the event" do
      expect(facade).to have_received(:log) do |event:, status:, context:|
        expect(event).to eq("$login")
        expect(status).to eq("$failed")
        expect(context.email).to eq(user.email)
      end
    end

    it "is successful" do
      expect(response).to be_successful
    end

    it "contains proper flash message" do
      expect(flash.alert).to match(/invalid email or password/i)
    end
  end

  context "with invalid request token" do
    before do
      allow(facade).to receive(:log).and_raise(Castle::InvalidParametersError)
      allow(CastleDevise.logger).to receive(:error)

      send_sign_in_request(user.email, "333", "token123")
    end

    it "logs the error" do
      expect(CastleDevise.logger).to have_received(:error)
    end

    it "is successful" do
      expect(response).to be_successful
    end

    it "contains proper flash message" do
      expect(flash.alert).to match(/invalid email or password/i)
    end
  end

  context "with correct password" do
    context "when Castle returns an allow verdict" do
      let(:policy_action) { "allow" }

      before { send_sign_in_request(user.email, "123456", "token123") }

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
      let(:policy_action) { "challenge" }

      before { send_sign_in_request(user.email, "123456", "token123") }

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
      let(:policy_action) { "deny" }

      before { send_sign_in_request(user.email, "123456", "token123") }

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

    context "when Castle raises InvalidParametersError" do
      before do
        allow(facade).to receive(:risk).and_raise(Castle::InvalidParametersError)
        send_sign_in_request(user.email, "123456", "token123")
      end

      context "and monitoring mode is enabled" do
        around do |example|
          CastleDevise.configuration.monitoring_mode = true
          example.run
          CastleDevise.configuration.monitoring_mode = false
        end

        it "authenticates the user" do
          expect(request.env["warden"].user(:user)).to eq(user)
        end
      end

      context "and monitoring mode is disabled" do
        it "does not authenticate the user" do
          expect(request.env["warden"].user(:user)).to be_nil
        end

        it "sets a flash message" do
          expect(flash.alert).to match(/invalid email or password/i)
        end
      end
    end

    context "when Castle raises other error" do
      before do
        allow(facade).to receive(:risk).and_raise(Castle::Error)
        allow(CastleDevise.logger).to receive(:error)
        send_sign_in_request(user.email, "123456", "token123")
      end

      it "logs the error" do
        expect(CastleDevise.logger).to have_received(:error)
      end

      it "authenticates the user" do
        expect(request.env["warden"].user(:user)).to eq(user)
      end
    end
  end
end
