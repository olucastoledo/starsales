class Crm::Deal < ApplicationRecord
  belongs_to :account
  belongs_to :crm_stage, class_name: 'Crm::Stage', foreign_key: 'crm_stage_id'
  has_many :deal_conversations, dependent: :destroy, foreign_key: 'crm_deal_id'
  has_many :conversations, through: :deal_conversations

  validates :name, presence: true
  validates :crm_stage_id, presence: true

  enum status: { open: 0, won: 1, lost: 2 }

  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_stage, ->(stage_id) { where(crm_stage_id: stage_id) }
  scope :open_deals, -> { where(status: :open) }
end
