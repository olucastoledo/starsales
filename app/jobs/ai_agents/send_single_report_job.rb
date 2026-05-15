module AiAgents
  # Generates and sends the report for a single AiAgentReportConfig.
  class SendSingleReportJob < ApplicationJob
    queue_as :low
    discard_on ActiveRecord::RecordNotFound

    def perform(config_id)
      config  = AiAgentReportConfig.find(config_id)
      account = config.account

      content = AiAgents::ReportGeneratorService.new(account, config).generate
      AiAgents::ReportSenderService.new(account, config, content).send!
    rescue StandardError => e
      Rails.logger.error("[AiAgents::Report] SendSingleReportJob failed for config #{config_id}: #{e.message}")
    end
  end
end
