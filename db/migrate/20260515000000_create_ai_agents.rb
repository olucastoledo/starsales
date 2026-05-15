class CreateAiAgents < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_agents do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :personality
      t.text :system_prompt
      t.float :temperature, default: 0.7
      t.string :model, default: 'gpt-4'
      t.boolean :enabled, default: true
      t.jsonb :custom_attributes, default: {}

      t.timestamps
    end

    add_foreign_key :ai_agents, :accounts
    add_index :ai_agents, :account_id
  end
end
