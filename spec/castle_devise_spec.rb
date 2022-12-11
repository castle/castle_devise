# frozen_string_literal: true

RSpec.describe CastleDevise do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  it "properly initializes the facade" do
    expect(described_class.sdk_facade).to be_a(CastleDevise::SdkFacade)
  end

  context "with facade override" do
    let(:facade_instance) { double }
    let(:facade) { class_double(::CastleDevise::SdkFacade, new: facade_instance) }

    before do
      described_class.configure { |config| config.castle_sdk_facade = facade }
    end

    it "uses the override facade" do
      expect(described_class.sdk_facade).to be(facade_instance)
    end
  end

  context "with client override" do
    let(:client) { instance_double(::Castle::Client) }

    before do
      described_class.configure { |config| config.castle_client = client }
    end

    it "uses the override client" do
      expect(described_class.castle).to be(client)
    end
  end
end
