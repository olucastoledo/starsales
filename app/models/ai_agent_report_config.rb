# == Schema Information
#
# Table name: ai_agent_report_configs
#
#  id                         :bigint           not null, primary key
#  custom_prompt              :text
#  enabled                    :boolean          default(TRUE), not null
#  frequency                  :string           default("daily"), not null
#  include_agent_stats        :boolean          default(TRUE), not null
#  include_conversation_count :boolean          default(TRUE), not null
#  include_handoff_rate       :boolean          default(TRUE), not null
#  include_tool_usage         :boolean          default(FALSE), not null
#  last_sent_at               :datetime
#  send_day_of_month          :integer
#  send_day_of_week           :integer
#  send_hour                  :integer          default(8), not null
#  whatsapp_number            :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :bigint           not null
#  inbox_id                   :bigint
#
# Indexes
#
#  index_ai_agent_report_configs_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class AiAgentReportConfig < ApplicationRecord
  FREQUENCIES = %w[daily weekly monthly].freeze

  belongs_to :account
  belongs_to :inbox, optional: true

  validates :frequency, inclusion: { in: FREQUENCIES }
  validates :send_hour, numericality: { in: 0..23 }
  validates :whatsapp_number, presence: true
  validates :send_day_of_week, numericality: { in: 0..6 }, allow_nil: true
  validates :send_day_of_month, numericality: { in: 1..31 }, allow_nil: true

  scope :enabled, -> { where(enabled: true) }

  # Returns configs that are due to be sent right now (called every hour by the job)
  def self.due_now
    now = Time.current

    enabled.select do |config|
      config.due_at?(now)
    end
  end

  def due_at?(time = Time.current)
    return false unless send_hour == time.utc.hour

    case frequency
    when 'daily'
      true
    when 'weekly'
      send_day_of_week == time.utc.wday
    when 'monthly'
      send_day_of_month == time.utc.day
    else
      false
    end
  end

  # Prevent duplicate sends within the same hour
  def already_sent_this_period?
    return false if last_sent_at.nil?

    last_sent_at >= 1.hour.ago
  end
end
