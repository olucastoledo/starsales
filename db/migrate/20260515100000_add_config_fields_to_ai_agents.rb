class AddConfigFieldsToAiAgents < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_agents, :debounce_delay_seconds, :integer, default: 5, null: false
    add_column :ai_agents, :context_window_messages, :integer, default: 50, null: false
  end
end
