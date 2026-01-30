module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model
  end
end
