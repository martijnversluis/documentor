class AppSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.[](key)
    find_by(key: key)&.value
  end

  def self.[]=(key, value)
    setting = find_or_initialize_by(key: key)
    setting.update!(value: value)
    value
  end
end
