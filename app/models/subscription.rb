class Subscription < ApplicationRecord
  include Taggable
  include PartyLinkable
  include Archivable

  COST_FREQUENCIES = %w[biweekly monthly quarterly yearly one_time].freeze
  CONTRACT_DURATIONS = %w[monthly quarterly yearly indefinite].freeze

  belongs_to :dossier, optional: true

  has_many :subscription_documents, dependent: :destroy
  has_many :documents, through: :subscription_documents

  attribute :cost, :decimal

  validates :name, presence: true
  validates :cost_frequency, inclusion: { in: COST_FREQUENCIES }, allow_blank: true
  validates :contract_duration, inclusion: { in: CONTRACT_DURATIONS }, allow_blank: true

  before_validation :set_cost_cents_from_cost

  scope :ordered, -> { order(:name) }

  def cost
    super || (cost_cents ? BigDecimal(cost_cents.to_s) / 100 : nil)
  end

  def active?
    ends_on.nil? || ends_on >= Date.current
  end

  def contract_duration_display
    case contract_duration
    when "monthly" then "Per maand"
    when "quarterly" then "Per kwartaal"
    when "yearly" then "Per jaar"
    when "indefinite" then "Onbepaalde tijd"
    end
  end

  def cost_display
    return nil if cost_cents.blank?

    formatted = format("%.2f", cost_cents / 100.0).tr(".", ",")
    case cost_frequency
    when "biweekly" then "#{formatted} / 2 weken"
    when "monthly" then "#{formatted} / maand"
    when "quarterly" then "#{formatted} / kwartaal"
    when "yearly" then "#{formatted} / jaar"
    when "one_time" then "#{formatted} eenmalig"
    else formatted
    end
  end

  private

  def set_cost_cents_from_cost
    if cost.present?
      self.cost_cents = (cost * 100).round
    end
  end
end
