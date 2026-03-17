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

  def sync_calendars!
    service = GoogleCalendarService.new(self)
    calendars = service.calendars

    calendars.each do |cal|
      calendar = google_calendars.find_or_initialize_by(calendar_id: cal[:id])
      attrs = { name: cal[:name], color: cal[:color] }
      attrs[:enabled] = cal[:primary] if calendar.new_record?
      calendar.update!(attrs)
    end

    # Remove calendars that no longer exist
    existing_ids = calendars.map { |c| c[:id] }
    google_calendars.where.not(calendar_id: existing_ids).destroy_all
  end
end
