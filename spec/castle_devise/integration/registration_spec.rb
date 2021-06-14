# frozen_string_literal: true

RSpec.describe "Registration attempt", type: :request do
  let(:facade) { instance_double(CastleDevise::SdkFacade) }

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
    let(:policy_action) { "allow" }

    it "sends requests to Castle" do
      expect(facade).to have_received(:filter) do |event:, rack_request:|
        expect(event).to eq("$registration")
        expect(rack_request).to be_a(Rack::Request)
      end
    end

    it "creates a user" do
      expect(request.env["warden"].user(:user)).to be_persisted
    end
  end

  describe "when Castle returns a challenge" do
    let(:policy_action) { "challenge" }

    it "sends requests to Castle" do
      expect(facade).to have_received(:filter) do |event:, rack_request:|
        expect(event).to eq("$registration")
        expect(rack_request).to be_a(Rack::Request)
      end
    end

    xit "does something useful"
  end

  describe "when Castle returns a deny verdict" do
    let(:policy_action) { "deny" }

    it "sends requests to Castle" do
      expect(facade).to have_received(:filter) do |event:, rack_request:|
        expect(event).to eq("$registration")
        expect(rack_request).to be_a(Rack::Request)
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