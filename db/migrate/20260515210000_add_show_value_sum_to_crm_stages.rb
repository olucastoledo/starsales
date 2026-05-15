class AddShowValueSumToCrmStages < ActiveRecord::Migration[7.1]
  def change
    add_column :crm_stages, :show_value_sum, :boolean, default: false, null: false
  end
end
