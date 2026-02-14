class GoogleAccount < ApplicationRecord
  encrypts :access_token
  encrypts :refresh_token

  has_many :google_calendars, dependent: :destroy
  has_many :meetings, dependent: :nullify

  validates :email, presence: true, uniqueness: { conditions: -> { kept } }

  scope :kept, -> { where(discarded_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }

  default_scope { kept }

  def discard
    update(discarded_at: Time.current)
  end

  def undiscard
    update(discarded_at: nil)
  end

  def discarded?
    discarded_at.present?
  end

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def enabled_calendars
    google_calendars.where(enabled: true)
  end
end
