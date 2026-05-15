class CreateAiAgentReportConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_report_configs do |t|
      t.bigint  :account_id,           null: false
      t.bigint  :inbox_id                                 # WhatsApp inbox to send from
      t.string  :frequency,            null: false, default: 'daily'   # daily | weekly | monthly
      t.integer :send_hour,            null: false, default: 8         # 0-23 UTC
      t.integer :send_day_of_week                                       # 0=Sun … 6=Sat (weekly)
      t.integer :send_day_of_month                                      # 1-31 (monthly)
      t.string  :whatsapp_number                                        # +5511999999999
      t.text    :custom_prompt                                          # AI instructions for the report
      t.boolean :include_conversation_count, null: false, default: true
      t.boolean :include_agent_stats,        null: false, default: true
      t.boolean :include_handoff_rate,       null: false, default: true
      t.boolean :include_tool_usage,         null: false, default: false
      t.boolean :enabled,                    null: false, default: true
      t.datetime :last_sent_at

      t.timestamps
    end

    add_index :ai_agent_report_configs, :account_id
    add_foreign_key :ai_agent_report_configs, :accounts
    add_foreign_key :ai_agent_report_configs, :inboxes, column: :inbox_id
  end
end
