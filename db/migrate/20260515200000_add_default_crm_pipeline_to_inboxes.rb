class AddDefaultCrmPipelineToInboxes < ActiveRecord::Migration[6.1]
  def change
    add_column :inboxes, :default_crm_pipeline_id, :bigint, null: true
    add_index :inboxes, :default_crm_pipeline_id
  end
end
