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

  # @param email [String]
  # @param password [String]
  # @param request_token [String]
  def send_sign_in_request(email, password, request_token)
    post "/users/sign_in",
      params: {
        user: {email: email, password: password},
        castle_request_token: request_token
      }
  end

  def send_authenticated_request
    get "/authenticated"
  end

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
    allow(facade).to receive(:risk).and_return(castle_risk_response)
  end

  context "when login hooks are disabled" do
    around do |example|
      User.castle_hooks[:after_login] = false
      example.run
      User.castle_hooks[:after_login] = true
    end

    context "with non-existing user" do
      before do
        allow(facade).to receive(:filter)

        send_sign_in_request("non-existing@example.com", "123456", "token123")
      end

      it "does not filter the event" do
        expect(facade).not_to have_received(:filter)
      end

      it "is successful" do
        expect(response).to be_successful
      end
    end

    context "with existing user" do
      before do
        allow(facade).to receive(:risk)

        send_sign_in_request(user.email, "123456", "token123")
      end

      it "does not send the event" do
        expect(facade).not_to have_received(:risk)
      end

      it "authenticates the user" do
        expect(request.env["warden"].user(:user)).to eq(user)
      end

      it "redirects" do
        expect(response.status).to eq(302)
      end
    end
  end

  context "with non-existing user" do
    before do
      allow(facade).to receive(:filter)

      send_sign_in_request("non-existing@example.com", "123456", "token123")
    end

    it "logs the event" do
      expect(facade).to have_received(:filter) do |event:, status:, context:|
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
      allow(facade).to receive(:filter)

      send_sign_in_request(user.email, "333", "token123")
    end

    it "logs the event" do
      expect(facade).to have_received(:filter) do |event:, status:, context:|
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
      allow(facade).to receive(:filter).and_raise(::Castle::InvalidRequestTokenError)
      allow(CastleDevise.logger).to receive(:warn)

      send_sign_in_request(user.email, "333", "token123")
    end

    it "logs the error" do
      expect(CastleDevise.logger).to have_received(:warn)
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
      let(:castle_risk_response) { allow_risk_response }

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
      let(:castle_risk_response) { challenge_risk_response }

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
      let(:castle_risk_response) { deny_risk_response }

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

    context "when Castle raises InvalidTokenError" do
      before do
        allow(facade).to receive(:risk).and_raise(Castle::InvalidRequestTokenError)
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

  context "when sending an event to an authenticated endpoint" do
    it "does not send an event to Castle" do
      send_authenticated_request
      # expect no RSpec errors on the facade instance_double
    end
  end
end
