class AppSetting < ApplicationRecord
  encrypts :encrypted_value

  validates :key, presence: true, uniqueness: true

  # Keys that should be stored encrypted
  ENCRYPTED_KEYS = %w[
    google_client_id
    google_client_secret
    github_client_id
    github_client_secret
  ].freeze

  def self.[](key)
    setting = find_or_create_by(key: key)

    if ENCRYPTED_KEYS.include?(key)
      setting.encrypted_value
    else
      setting.value
    end
  end

  def self.[]=(key, value)
    setting = find_or_initialize_by(key: key)

    if ENCRYPTED_KEYS.include?(key)
      setting.update!(encrypted_value: value, value: nil)
    else
      setting.update!(value: value, encrypted_value: nil)
    end

    value
  end
end
