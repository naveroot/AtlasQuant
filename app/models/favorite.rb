class Favorite < ApplicationRecord
  belongs_to :user

  validates :secid, presence: true, uniqueness: { scope: :user_id }
end
