# frozen_string_literal: true

# Based on the $profile_update event.
RSpec.describe "Password reset", type: :request do
  subject(:send_password_reset) do
    put "/users/password",
      params: {
        user: {
          reset_password_token: password_reset_token,
          password: new_password,
          password_confirmation: new_password_confirmation
        },
        castle_request_token: request_token
      }
  end

  let(:facade) { instance_spy(CastleDevise::SdkFacade) }
  let(:request_token) { "token123" }
  let(:email) { "user@example.com" }
  let(:password) { "123456" }
  let(:new_password) { "654321" }
  let(:new_password_confirmation) { new_password }
  let!(:user) do
    User.create!(
      email: email,
      password: password,
      password_confirmation: password
    )
  end
  let(:password_reset_token) { user.send_reset_password_instructions }

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
  end

  context "when profile update hooks are disabled" do
    around do |example|
      User.castle_hooks[:profile_update] = false
      example.run
      User.castle_hooks[:profile_update] = true
    end

    before do
      password_reset_token

      send_password_reset
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
      password_reset_token

      send_password_reset
    end

    context "when password successfully changed" do
      it "updates the password" do
        expect(user.reload.valid_password?(new_password)).to eq(true)
      end

      it "logs profile_update event with succeeded status" do
        expect(facade).to have_received(:log).with(
          event: "$profile_update",
          status: "$succeeded",
          context: have_attributes(email: email, resource: user)
        )
      end
    end

    context "when password failed to change" do
      let(:new_password_confirmation) { "abcdef" }

      it "does not update the password" do
        expect(user.reload.valid_password?(password)).to eq(true)
      end

      it "logs profile_update event with failed status" do
        expect(facade).to have_received(:log).with(
          event: "$profile_update",
          status: "$failed",
          context: have_attributes(email: email, resource: user)
        )
      end
    end

    context 'when resource does not exist' do
      pending
    end
  end

  context "when profile update hooks are enabled and there are errors" do
    context "when Castle raises error" do
      before do
        allow(facade).to receive(:log).and_raise(Castle::Error)

        allow(CastleDevise.logger).to receive(:error)

        password_reset_token

        send_password_reset
      end

      it "logs the error" do
        expect(CastleDevise.logger).to have_received(:error)
      end

      it "updates the password" do
        expect(user.reload.valid_password?(new_password)).to eq(true)
      end
    end
  end
end
