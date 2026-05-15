# == Schema Information
#
# Table name: crm_pipelines
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_crm_pipelines_on_account_id           (account_id)
#  index_crm_pipelines_on_account_id_and_name  (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class CrmPipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'CrmStage', foreign_key: 'crm_pipeline_id', dependent: :destroy
  has_many :deals, class_name: 'CrmDeal', through: :stages, source: :crm_deals
  has_many :inboxes, foreign_key: :default_crm_pipeline_id, dependent: :nullify, inverse_of: :default_crm_pipeline
end
