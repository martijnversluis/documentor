module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end

  def tag_list
    tags.pluck(:name).join(", ")
  end

  def tag_list=(names)
    self.tags = names.to_s.split(",").map(&:strip).reject(&:blank?).uniq.map do |name|
      Tag.find_or_create_by(name: name)
    end
  end
end
