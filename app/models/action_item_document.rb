class ActionItemDocument < ApplicationRecord
  belongs_to :action_item
  belongs_to :document

  validates :document_id, uniqueness: { scope: :action_item_id }
end
