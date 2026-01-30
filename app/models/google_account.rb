class GoogleAccount < ApplicationRecord
  encrypts :access_token
  encrypts :refresh_token

  has_many :google_calendars, dependent: :destroy
  has_many :meetings, dependent: :destroy

  validates :email, presence: true, uniqueness: true

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def enabled_calendars
    google_calendars.where(enabled: true)
  end
end
