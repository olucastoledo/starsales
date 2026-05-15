# == Schema Information
#
# Table name: ai_agent_logs
#
#  id              :bigint           not null, primary key
#  action          :string
#  error_message   :text
#  payload         :jsonb
#  status          :integer          default("success")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  ai_agent_id     :bigint           not null
#  conversation_id :bigint           not null
#
# Indexes
#
#  index_ai_agent_logs_on_account_id_and_created_at  (account_id,created_at)
#  index_ai_agent_logs_on_conversation_id            (conversation_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (ai_agent_id => ai_agents.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#
class AiAgentLog < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :ai_agent

  enum status: { success: 0, error: 1, skipped: 2 }

  scope :by_action, ->(action) { where(action: action) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }

  def self.log_action(account_id, conversation_id, ai_agent_id, action, payload = {}, error_message = nil)
    status = error_message.present? ? :error : :success
    create(
      account_id: account_id,
      conversation_id: conversation_id,
      ai_agent_id: ai_agent_id,
      action: action,
      payload: payload,
      status: status,
      error_message: error_message
    )
  end
end
