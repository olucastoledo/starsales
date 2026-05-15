# == Schema Information
#
# Table name: ai_agent_tools
#
#  id           :bigint           not null, primary key
#  auth_config  :jsonb
#  description  :text
#  enabled      :boolean          default(TRUE)
#  endpoint_url :string
#  name         :string           not null
#  schema       :jsonb
#  tool_type    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  ai_agent_id  :bigint           not null
#
# Indexes
#
#  index_ai_agent_tools_on_account_id   (account_id)
#  index_ai_agent_tools_on_ai_agent_id  (ai_agent_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (ai_agent_id => ai_agents.id) ON DELETE => cascade
#
class AiAgentTool < ApplicationRecord
  belongs_to :account
  belongs_to :ai_agent

  validates :name, presence: true
  validates :ai_agent_id, uniqueness: { scope: :name }
  validates :schema, presence: true
  validates :endpoint_url, presence: true, if: proc { tool_type == 'api' }

  scope :enabled, -> { where(enabled: true) }
  scope :by_type, ->(type) { where(tool_type: type) }
end
