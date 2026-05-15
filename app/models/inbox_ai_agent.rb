# == Schema Information
#
# Table name: inbox_ai_agents
#
#  id          :bigint           not null, primary key
#  enabled     :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  ai_agent_id :bigint           not null
#  inbox_id    :bigint           not null
#
# Indexes
#
#  index_inbox_ai_agents_on_account_id                (account_id)
#  index_inbox_ai_agents_on_inbox_id_and_ai_agent_id  (inbox_id,ai_agent_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (ai_agent_id => ai_agents.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class InboxAiAgent < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :ai_agent

  validates :inbox_id, uniqueness: { scope: :ai_agent_id }

  before_validation :set_account_id

  private

  def set_account_id
    self.account_id = inbox&.account_id
  end
end
