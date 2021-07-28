# frozen_string_literal: true

RSpec.describe Devise::Models::CastleProtectable do
  it "has a default value for castle_hooks" do
    expect(User.castle_hooks).to eq(
      before_registration: true,
      after_login: true,
      after_password_reset_request: true,
      profile_update: true
    )
  end
end
