# frozen_string_literal: true

RSpec.describe CastleDevise do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  it "properly initializes the facade" do
    expect(described_class.sdk_facade).to be_a(CastleDevise::SdkFacade)
  end
end
