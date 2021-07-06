# frozen_string_literal: true

RSpec.describe CastleDevise::Configuration do
  subject(:configuration) { described_class.new }

  it "can add multiple before_request hooks" do
    configuration.before_request { |_| puts 1 }
    configuration.before_request { |_| puts 2 }

    expect(configuration.before_request_hooks.size).to eq(2)
  end

  it "can add multiple after_request hooks" do
    configuration.after_request { |_| puts 1 }
    configuration.after_request { |_| puts 2 }

    expect(configuration.after_request_hooks.size).to eq(2)
  end
end
