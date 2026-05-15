class CreateAiAgentConversationStates < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_agent_conversation_states do |t|
      t.bigint :account_id, null: false
      t.bigint :conversation_id, null: false
      t.bigint :ai_agent_id, null: false
      t.datetime :paused_at
      t.string :paused_by
      t.text :pause_reason

      t.timestamps
    end

    add_foreign_key :ai_agent_conversation_states, :accounts
    add_foreign_key :ai_agent_conversation_states, :conversations, on_delete: :cascade
    add_foreign_key :ai_agent_conversation_states, :ai_agents, on_delete: :cascade
    add_index :ai_agent_conversation_states, [:conversation_id, :ai_agent_id], unique: true, name: 'index_ai_agent_conv_states_on_conv_and_agent'
    add_index :ai_agent_conversation_states, :account_id
  end
end
