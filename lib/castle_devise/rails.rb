# frozen_string_literal: true

ActiveSupport.on_load(:action_controller) do
  include CastleDevise::Controllers::Helpers
end

ActiveSupport.on_load(:action_view) do
  include CastleDevise::Helpers::CastleHelper
end

ActiveSupport::Reloader.to_prepare do
  CastleDevise::Patches.apply
end
