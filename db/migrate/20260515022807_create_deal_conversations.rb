class CreateDealConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :deal_conversations do |t|
      t.references :crm_deal, null: false, foreign_key: { to_table: :crm_deals }, index: true
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
