class CreateAiAgentTools < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_agent_tools do |t|
      t.bigint :account_id, null: false
      t.bigint :ai_agent_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :tool_type
      t.jsonb :schema
      t.string :endpoint_url
      t.jsonb :auth_config, default: {}
      t.boolean :enabled, default: true

      t.timestamps
    end

    add_foreign_key :ai_agent_tools, :accounts
    add_foreign_key :ai_agent_tools, :ai_agents, on_delete: :cascade
    add_index :ai_agent_tools, :account_id
    add_index :ai_agent_tools, :ai_agent_id
  end
end
