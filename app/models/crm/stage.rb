class Crm::Stage < ApplicationRecord
  belongs_to :crm_pipeline, class_name: 'Crm::Pipeline', foreign_key: 'crm_pipeline_id'
  has_many :deals, dependent: :nullify, foreign_key: 'crm_stage_id', class_name: 'Crm::Deal'

  validates :name, presence: true
  validates :position, presence: true
  validates :crm_pipeline_id, presence: true

  scope :ordered, -> { order(:position) }
end
