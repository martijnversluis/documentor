class PartyLink < ApplicationRecord
  belongs_to :party
  belongs_to :linkable, polymorphic: true
end
