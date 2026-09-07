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

  describe "#castle_js_pk" do
    it "returns publishable_key when present" do
      configuration.publishable_key = "pk_x"
      configuration.app_id = "app_y"

      expect(configuration.castle_js_pk).to eq("pk_x")
    end

    it "falls back to app_id" do
      configuration.app_id = "app_y"

      expect(configuration.castle_js_pk).to eq("app_y")
    end
  end
end
