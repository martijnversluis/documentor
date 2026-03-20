class GithubHiddenItem < ApplicationRecord
  validates :item_id, presence: true, uniqueness: true
  validates :action, presence: true, inclusion: { in: %w[snooze ignore promote] }

  scope :active, -> {
    where(action: %w[ignore promote])
      .or(where(action: "snooze").where("created_at >= ?", Date.current.beginning_of_day))
  }

  def self.hidden_item_ids
    active.pluck(:item_id)
  end
end
