class CreateCrmStages < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_stages do |t|
      t.references :crm_pipeline, null: false, foreign_key: { to_table: :crm_pipelines }
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.text :description

      t.timestamps
    end

    add_index :crm_stages, [:crm_pipeline_id, :position]
  end
end
