# == Schema Information
#
# Table name: ai_agents
#
#  id                      :bigint           not null, primary key
#  context_window_messages :integer          default(50), not null
#  custom_attributes       :jsonb
#  debounce_delay_seconds  :integer          default(5), not null
#  description             :text
#  enabled                 :boolean          default(TRUE)
#  model                   :string           default("gpt-4")
#  name                    :string           not null
#  personality             :string
#  system_prompt           :text
#  temperature             :float            default(0.7)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#
# Indexes
#
#  index_ai_agents_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AiAgent < ApplicationRecord
  belongs_to :account
  has_many :ai_agent_tools, dependent: :destroy
  has_many :ai_agent_conversation_states, dependent: :destroy
  has_many :ai_agent_logs, dependent: :destroy
  has_many :inbox_ai_agents, dependent: :destroy
  has_many :inboxes, through: :inbox_ai_agents

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :system_prompt, presence: true
  validates :model, presence: true
  validates :temperature, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2 }
  validates :debounce_delay_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 60 }
  validates :context_window_messages, numericality: { only_integer: true, greater_than_or_equal_to: 5, less_than_or_equal_to: 200 }

  scope :enabled, -> { where(enabled: true) }
  scope :by_personality, ->(personality) { where(personality: personality) }
end
