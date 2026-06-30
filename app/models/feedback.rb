class Feedback < ApplicationRecord
  belongs_to :user, optional: true

  validates :message, presence: true, length: { maximum: 5000 }
end
