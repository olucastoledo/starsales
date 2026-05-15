# == Schema Information
#
# Table name: deal_conversations
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  crm_deal_id     :bigint           not null
#
# Indexes
#
#  index_deal_conversations_on_conversation_id  (conversation_id) UNIQUE
#  index_deal_conversations_on_crm_deal_id      (crm_deal_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (crm_deal_id => crm_deals.id)
#
class DealConversation < ApplicationRecord
  belongs_to :crm_deal, class_name: 'CrmDeal', foreign_key: 'crm_deal_id'
  belongs_to :conversation

  validates :crm_deal_id, :conversation_id, presence: true
  validates :conversation_id, uniqueness: true
end
