class SubscriptionDocument < ApplicationRecord
  belongs_to :subscription
  belongs_to :document

  validates :document_id, uniqueness: { scope: :subscription_id }
end
