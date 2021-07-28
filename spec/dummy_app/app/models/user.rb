class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :castle_protectable, castle_hooks: {
      after_login: true,
      after_password_reset_request: true,
      before_registration: true
    }
end
