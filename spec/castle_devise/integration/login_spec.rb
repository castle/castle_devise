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

  before do
    allow(CastleDevise).to receive(:sdk_facade).and_return(facade)
    allow(facade).to receive(:risk).and_return(castle_risk_response)
    allow(facade).to receive(:filter).and_return(castle_filter_response)
  end

  context "when filter denies" do
    let(:castle_filter_response) do
      {
        risk: 0.92,
        signals: {},
        policy: {
          action: "deny",
          name: "My Policy",
          id: "e14c5a8d-c682-4a22-bbca-04fa6b98ad0c",
          revision_id: "b5cf794e-88c0-426e-8276-037ba1e7ceca"
        },
      }
    end
    let(:castle_risk_response) { double }

    before do
      post "/users/sign_in",
           params: {
             user: {email: user.email, password: "123456"},
             castle_request_token: "token123"
           }
    end

    it "calls the facade with valid arguments" do
      expect(facade).to have_received(:filter) do |event:, context:|
        expect(event).to eq("$login")
        expect(context).to be_a(CastleDevise::Context)
      end
    end

    it "does not call risk" do
      expect(facade).not_to have_received(:risk)
    end

    it "does not authenticate the user" do
      expect(request.env["warden"].user(:user)).to be_nil
    end

    it "sets a flash message" do
      expect(flash.alert).to match(/invalid email or password/i)
    end

    it "redirects to sign_in path" do
      expect(response).to redirect_to('/users/sign_in')
    end
  end

  context "with correct password" do
    let(:castle_filter_response) do
      {
        risk: 0.32,
        signals: {},
        policy: {
          action: "allow",
          name: "My Policy",
          id: "e14c5a8d-c682-4a22-bbca-04fa6b98ad0c",
          revision_id: "b5cf794e-88c0-426e-8276-037ba1e7ceca"
        },
      }
    end

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

      it "redirects to sign_in path" do
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end
end
