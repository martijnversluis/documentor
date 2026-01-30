class ExpiringItem < ApplicationRecord
  validates :name, presence: true
  validates :expires_at, presence: true

  scope :ordered, -> { order(:expires_at) }
  scope :expired, -> { where("expires_at < ?", Date.current) }
  scope :expiring_soon, ->(days = 30) { where(expires_at: Date.current..days.days.from_now) }
  scope :active, -> { where("expires_at >= ?", Date.current) }

  before_validation :set_default_notify_days

  def expired?
    expires_at < Date.current
  end

  def expiring_soon?(days = nil)
    days ||= notify_days_before || 30
    expires_at >= Date.current && expires_at <= days.days.from_now
  end

  def days_until_expiration
    (expires_at - Date.current).to_i
  end

  def status
    if expired?
      :expired
    elsif expiring_soon?
      :expiring_soon
    else
      :valid
    end
  end

  def status_color
    case status
    when :expired then "red"
    when :expiring_soon then "orange"
    else "green"
    end
  end

  private

  def set_default_notify_days
    self.notify_days_before ||= 30
  end
end
