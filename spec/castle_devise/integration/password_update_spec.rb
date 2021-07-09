# frozen_string_literal: true

RSpec.describe "Password update", type: :request do
  subject(:send_password_update) do
    # First, we need to sign in so we can update the password next
    post "/users/sign_in",
      params: {
        user: {
          email: email,
          password: password
        },
        castle_request_token: request_token
      }

    put "/users",
      params: {
        email: email,
        user: {
          current_password: current_password,
          password: new_password,
          password_confirmation: new_password
        },
        castle_request_token: request_token
      }
  end

  let(:facade) { instance_double(CastleDevise::SdkFacade) }
  let(:request_token) { "token123" }
  let(:email) { "user@example.com" }
  let(:password) { "123456" }
  let(:new_password) { "654321" }
  let(:current_password) { password }
  let!(:user) do
    User.create!(
      email: email,
      password: password,
      password_confirmation: password
    )
  end
  let(:login_castle_risk_response) { allow_risk_response }
  let(:profile_update_castle_risk_response) { allow_risk_response }

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)

    allow(facade).to receive(:log)
  end

  context "when profile update hooks are disabled" do
    around do |example|
      User.castle_hooks[:profile_update] = false
      example.run
      User.castle_hooks[:profile_update] = true
    end

    before do
      allow(facade).to receive(:risk).and_return(login_castle_risk_response)

      send_password_update
    end

    it "does not use risk action for the profile_update event" do
      expect(facade).not_to have_received(:risk).with(
        event: "$profile_update",
        context: have_attributes(email: email)
      )
    end

    it "does not log the profile_update event" do
      expect(facade).not_to have_received(:log)
    end

    it "updates the password" do
      expect(user.reload.valid_password?(new_password)).to eq(true)
    end
  end

  context "when profile update hooks are enabled" do
    before do
      allow(facade).to receive(:risk).and_return(
        login_castle_risk_response, profile_update_castle_risk_response
      )

      send_password_update
    end

    context "when Castle returns allow action" do
      context "when password successfully changed" do
        it "updates the password" do
          expect(user.reload.valid_password?(new_password)).to eq(true)
        end

        it "performs risk action with profile_update event" do
          expect(facade).to have_received(:risk).with(
            event: "$profile_update",
            context: have_attributes(email: email)
          )
        end

        it "logs profile_update event with succeeded status" do
          expect(facade).to have_received(:log).with(
            event: "$profile_update",
            status: "$succeeded",
            context: have_attributes(email: email)
          )
        end

        it "keeps the user authenticated" do
          expect(request.env["warden"].user(:user)).to eq(user)
        end

        it "stores context and response in Rack env" do
          expect(request.env["castle_devise.risk_response"])
            .to eq(profile_update_castle_risk_response)

          expect(request.env["castle_devise.risk_context"]).to be_a(CastleDevise::Context)
        end
      end

      context "when password failed to change" do
        let(:current_password) { "abcdef" }

        it "does not update the password" do
          expect(user.reload.valid_password?(password)).to eq(true)
        end

        it "performs risk action with profile_update event" do
          expect(facade).to have_received(:risk).with(
            event: "$profile_update",
            context: have_attributes(email: email)
          )
        end

        it "logs profile_update event with failed status" do
          expect(facade).to have_received(:log).with(
            event: "$profile_update",
            status: "$failed",
            context: have_attributes(email: email)
          )
        end
      end
    end

    context "when Castle returns challenge action" do
      let(:profile_update_castle_risk_response) { challenge_risk_response }

      context "when password successfully changed" do
        it "updates the password" do
          expect(user.reload.valid_password?(new_password)).to eq(true)
        end

        it "performs risk action with profile_update event" do
          expect(facade).to have_received(:risk).with(
            event: "$profile_update",
            context: have_attributes(email: email)
          )
        end

        it "logs profile_update event with succeeded status" do
          expect(facade).to have_received(:log).with(
            event: "$profile_update",
            status: "$succeeded",
            context: have_attributes(email: email)
          )
        end

        it "keeps the user authenticated" do
          expect(request.env["warden"].user(:user)).to eq(user)
        end

        it "stores context and response in Rack env" do
          expect(request.env["castle_devise.risk_response"])
            .to eq(profile_update_castle_risk_response)

          expect(request.env["castle_devise.risk_context"]).to be_a(CastleDevise::Context)
        end
      end

      context "when password failed to change" do
        let(:current_password) { "abcdef" }

        it "does not update the password" do
          expect(user.reload.valid_password?(password)).to eq(true)
        end

        it "performs risk action with profile_update event" do
          expect(facade).to have_received(:risk).with(
            event: "$profile_update",
            context: have_attributes(email: email)
          )
        end

        it "logs profile_update event with failed status" do
          expect(facade).to have_received(:log).with(
            event: "$profile_update",
            status: "$failed",
            context: have_attributes(email: email)
          )
        end
      end
    end

    context "when Castle returns deny action" do
      let(:profile_update_castle_risk_response) { deny_risk_response }

      it "does not update the password" do
        expect(user.reload.valid_password?(password)).to eq(true)
      end

      it "performs risk action with profile_update event" do
        expect(facade).to have_received(:risk).with(
          event: "$profile_update",
          context: have_attributes(email: email)
        )
      end

      it "logs out the user" do
        expect(request.env["warden"].user(:user)).to be_nil
      end

      it "stores context and response in Rack env" do
        expect(request.env["castle_devise.risk_response"])
          .to eq(profile_update_castle_risk_response)
        expect(request.env["castle_devise.risk_context"]).to be_a(CastleDevise::Context)
      end
    end
  end

  context "when profile update hooks are enabled and there are errors" do
    context "when Castle raises InvalidParametersError" do
      before do
        call_risk_count = 0
        allow(facade).to receive(:risk) do
          call_risk_count += 1
          call_risk_count >= 2 ? raise(Castle::InvalidParametersError) : login_castle_risk_response
        end

        send_password_update
      end

      it "logs out the user" do
        expect(request.env["warden"].user(:user)).to be_nil
      end

      it "sets a flash message" do
        expect(flash.alert).to match(/invalid email or password/i)
      end

      it "does not update the password" do
        expect(user.reload.valid_password?(password)).to eq(true)
      end
    end

    context "when Castle raises other error" do
      before do
        call_risk_count = 0
        allow(facade).to receive(:risk) do
          call_risk_count += 1
          call_risk_count >= 2 ? raise(Castle::Error) : login_castle_risk_response
        end

        allow(CastleDevise.logger).to receive(:error)

        send_password_update
      end

      it "logs the error" do
        expect(CastleDevise.logger).to have_received(:error)
      end

      it "keeps the user authenticated" do
        expect(request.env["warden"].user(:user)).to eq(user)
      end

      it "updates the password" do
        expect(user.reload.valid_password?(new_password)).to eq(true)
      end
    end
  end
end
