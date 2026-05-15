class CreateAiAgentLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_agent_logs do |t|
      t.bigint :account_id, null: false
      t.bigint :conversation_id, null: false
      t.bigint :ai_agent_id, null: false
      t.string :action
      t.jsonb :payload, default: {}
      t.integer :status, default: 0
      t.text :error_message

      t.timestamps
    end

    add_foreign_key :ai_agent_logs, :accounts
    add_foreign_key :ai_agent_logs, :conversations, on_delete: :cascade
    add_foreign_key :ai_agent_logs, :ai_agents, on_delete: :cascade
    add_index :ai_agent_logs, [:account_id, :created_at]
    add_index :ai_agent_logs, :conversation_id
  end
end
