class AddEnableCrmToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :enable_crm, :boolean, default: false
  end
end
