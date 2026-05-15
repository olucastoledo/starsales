class CreateCrmDeals < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_deals do |t|
      t.references :account, null: false, foreign_key: true
      t.references :crm_stage, null: false, foreign_key: { to_table: :crm_stages }
      t.string :name, null: false
      t.decimal :value, precision: 15, scale: 2
      t.date :expected_close_date
      t.integer :status, default: 0, null: false
      t.text :description

      t.timestamps
    end

    add_index :crm_deals, [:account_id, :crm_stage_id]
    add_index :crm_deals, :status
  end
end
