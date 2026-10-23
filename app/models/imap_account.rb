class ImapAccount < ApplicationRecord
  encrypts :password

  validates :label, :host, :username, :password, :folder, presence: true
  validates :port, numericality: { only_integer: true, in: 1..65535 }
  validates :username, uniqueness: { scope: :host, conditions: -> { kept } }

  scope :kept, -> { where(discarded_at: nil) }
  scope :enabled, -> { kept.where(enabled: true) }

  default_scope { kept }

  def discard!
    update!(discarded_at: Time.current, enabled: false)
  end

  def discarded?
    discarded_at.present?
  end
end
