# == Schema Information
#
# Table name: ai_agent_conversation_states
#
#  id              :bigint           not null, primary key
#  pause_reason    :text
#  paused_at       :datetime
#  paused_by       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  ai_agent_id     :bigint           not null
#  conversation_id :bigint           not null
#
# Indexes
#
#  index_ai_agent_conv_states_on_conv_and_agent      (conversation_id,ai_agent_id) UNIQUE
#  index_ai_agent_conversation_states_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (ai_agent_id => ai_agents.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#
class AiAgentConversationState < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :ai_agent

  validates :conversation_id, uniqueness: { scope: :ai_agent_id }

  scope :active, -> { where(paused_at: nil) }
  scope :paused, -> { where.not(paused_at: nil) }

  def paused?
    paused_at.present?
  end

  def resume!
    update(paused_at: nil, paused_by: nil, pause_reason: nil)
  end

  def pause!(paused_by: nil, reason: nil)
    update(paused_at: Time.current, paused_by: paused_by, pause_reason: reason)
  end
end
