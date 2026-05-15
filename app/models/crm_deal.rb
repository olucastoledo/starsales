# == Schema Information
#
# Table name: crm_deals
#
#  id                  :bigint           not null, primary key
#  description         :text
#  expected_close_date :date
#  name                :string           not null
#  status              :integer          default("open"), not null
#  value               :decimal(15, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  crm_stage_id        :bigint           not null
#
# Indexes
#
#  index_crm_deals_on_account_id                   (account_id)
#  index_crm_deals_on_account_id_and_crm_stage_id  (account_id,crm_stage_id)
#  index_crm_deals_on_crm_stage_id                 (crm_stage_id)
#  index_crm_deals_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (crm_stage_id => crm_stages.id)
#
class CrmDeal < ApplicationRecord
  belongs_to :account
  belongs_to :crm_stage

  has_one :deal_conversation, dependent: :destroy
  has_one :conversation, through: :deal_conversation

  enum :status, { open: 0, won: 1, lost: 2 }, prefix: true
end
