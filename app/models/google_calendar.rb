class GoogleCalendar < ApplicationRecord
  belongs_to :google_account

  validates :calendar_id, presence: true, uniqueness: { scope: :google_account_id }

  scope :enabled, -> { where(enabled: true) }
end
