class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  validates :password_confirmation, presence: true

  mount_uploader :image, ImageUploader
end
