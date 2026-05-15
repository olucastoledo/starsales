# == Schema Information
#
# Table name: crm_stages
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string           not null
#  position        :integer          default(0), not null
#  show_value_sum  :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  crm_pipeline_id :bigint           not null
#
# Indexes
#
#  index_crm_stages_on_crm_pipeline_id               (crm_pipeline_id)
#  index_crm_stages_on_crm_pipeline_id_and_position  (crm_pipeline_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (crm_pipeline_id => crm_pipelines.id)
#
class CrmStage < ApplicationRecord
  belongs_to :crm_pipeline
  has_many :crm_deals, foreign_key: 'crm_stage_id', dependent: :destroy

  scope :ordered, -> { order(:position) }
end
