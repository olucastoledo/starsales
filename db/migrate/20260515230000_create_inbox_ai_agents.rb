class CreateInboxAiAgents < ActiveRecord::Migration[7.0]
  def change
    create_table :inbox_ai_agents do |t|
      t.bigint :account_id, null: false
      t.bigint :inbox_id,    null: false
      t.bigint :ai_agent_id, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :inbox_ai_agents, :account_id
    add_index :inbox_ai_agents, [:inbox_id, :ai_agent_id], unique: true
    add_foreign_key :inbox_ai_agents, :accounts
    add_foreign_key :inbox_ai_agents, :inboxes
    add_foreign_key :inbox_ai_agents, :ai_agents
  end
end
