module PartyLinkable
  extend ActiveSupport::Concern

  included do
    has_many :party_links, as: :linkable, dependent: :destroy
    has_many :parties, through: :party_links
  end
end
