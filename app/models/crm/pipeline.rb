class Crm::Pipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, dependent: :destroy, foreign_key: 'crm_pipeline_id', class_name: 'Crm::Stage'
  has_many :deals, through: :stages, source: :deals, class_name: 'Crm::Deal'

  validates :name, presence: true, uniqueness: { scope: :account_id }
end
