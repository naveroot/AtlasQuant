class FavoriteInstrument < ApplicationRecord
  belongs_to :user

  validates :secid, presence: true, uniqueness: { scope: :user_id }
  validates :shortname, :asset_code, presence: true
end
