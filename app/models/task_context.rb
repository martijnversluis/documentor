class TaskContext < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(Arel.sql("position IS NULL, position ASC, name ASC")) }

  def display_name
    "@#{name}"
  end
end
