module AiAgents
  class GenerateDailyReportJob < ApplicationJob
    queue_as :default

    def perform
      Account.find_each do |account|
        generate_report_for_account(account)
      end
    end

    private

    def generate_report_for_account(account)
      date_range = 1.day.ago.beginning_of_day..Time.current.end_of_day
      logs = AiAgentLog.where(account_id: account.id, created_at: date_range)

      return if logs.empty?

      report_data = {
        account_id: account.id,
        date: Date.current,
        total_conversations_handled: count_conversations(logs),
        total_messages_processed: logs.count,
        successful_actions: logs.where(status: :success).count,
        failed_actions: logs.where(status: :error).count,
        skipped_actions: logs.where(status: :skipped).count,
        agent_statistics: calculate_agent_stats(logs),
        action_breakdown: calculate_action_breakdown(logs)
      }

      # TODO: Email report or save to database for later retrieval
      Rails.logger.info("Daily AI Agent Report for Account #{account.id}: #{report_data}")
    end

    def count_conversations(logs)
      logs.pluck(:conversation_id).uniq.count
    end

    def calculate_agent_stats(logs)
      logs.group_by(:ai_agent_id).transform_values do |agent_logs|
        {
          conversations: agent_logs.pluck(:conversation_id).uniq.count,
          messages: agent_logs.count,
          success_rate: (agent_logs.where(status: :success).count.to_f / agent_logs.count * 100).round(2)
        }
      end
    end

    def calculate_action_breakdown(logs)
      logs.group_by(:action).transform_values(&:count)
    end
  end
end
