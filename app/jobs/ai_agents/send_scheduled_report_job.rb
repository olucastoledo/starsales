module AiAgents
  # Runs every hour via Sidekiq-Cron.
  # Checks all enabled report configs and sends those that are due.
  class SendScheduledReportJob < ApplicationJob
    queue_as :low

    def perform
      AiAgentReportConfig.due_now.each do |config|
        next if config.already_sent_this_period?

        SendSingleReportJob.perform_later(config.id)
      end
    end
  end
end
