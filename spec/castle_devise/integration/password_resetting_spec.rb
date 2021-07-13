# frozen_string_literal: true

RSpec.describe "Password reset request", type: :request do
  subject(:send_password_reset_request) do
    post "/users/password", params: {user: {email: email}}
  end

  let(:facade) { instance_double(CastleDevise::SdkFacade) }
  let!(:user) do
    User.create!(
      email: "user@example.com",
      password: "123456",
      password_confirmation: "123456"
    )
  end

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)

    allow(facade).to receive(:log)
  end

  context "when password reset hooks are disabled" do
    around do |example|
      User.castle_hooks[:after_password_reset_request] = false
      example.run
      User.castle_hooks[:after_password_reset_request] = true
    end

    before { send_password_reset_request }

    context "with non-existing user" do
      let(:email) { "non-existing-user@example.com" }

      it "does not log the password_reset_requested event" do
        expect(facade).not_to have_received(:log)
      end

      it "does not set reset_password_sent_at on user" do
        expect(user.reset_password_sent_at).to eq(nil)
      end
    end

    context "with existing user" do
      let(:email) { "user@example.com" }

      it "does not log the password_reset_requested event" do
        expect(facade).not_to have_received(:log)
      end

      it "does not set reset_password_sent_at on user" do
        expect(user.reset_password_sent_at).to eq(nil)
      end
    end
  end

  context "when password reset hooks are enabled" do
    context "with non-existing user" do
      let(:email) { "non-existing-user@example.com" }

      before { send_password_reset_request }

      it "logs password_reset_requested event with failed status" do
        expect(facade).to have_received(:log) do |event:, status:, context:|
          expect(event).to eq("$password_reset_requested")
          expect(status).to eq("$failed")
          expect(context.email).to eq(email)
        end
      end

      it "sets reset_password_sent_at on user" do
        expect(user.reload.reset_password_sent_at).to eq(nil)
      end
    end

    context "with existing user" do
      let(:email) { "user@example.com" }

      before { send_password_reset_request }

      it "logs password_reset_requested event with succeeded status" do
        expect(facade).to have_received(:log) do |event:, status:, context:|
          expect(event).to eq("$password_reset_requested")
          expect(status).to eq("$succeeded")
          expect(context.email).to eq(email)
        end
      end

      it "sets reset_password_sent_at on user" do
        expect(user.reload.reset_password_sent_at).not_to eq(nil)
      end
    end

    context "when Castle raises error" do
      let(:email) { "user@example.com" }

      before do
        allow(facade).to receive(:log).and_raise(Castle::Error)

        allow(CastleDevise.logger).to receive(:error)

        send_password_reset_request
      end

      it "logs the error" do
        expect(CastleDevise.logger).to have_received(:error)
      end

      it "sets reset_password_sent_at on user" do
        expect(user.reload.reset_password_sent_at).not_to eq(nil)
      end
    end
  end
end
