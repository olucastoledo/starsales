# frozen_string_literal: true

Rails.application.config.after_initialize do
  api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.presence || ENV.fetch('OPENAI_API_KEY', nil)
  api_endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence || LlmConstants::OPENAI_API_ENDPOINT

  if api_key.present?
    OpenAI.configure do |config|
      config.access_token = api_key
      config.uri_base = "#{api_endpoint.chomp('/')}/v1" if api_endpoint.present?
    end
  end
rescue StandardError => e
  Rails.logger.error "Failed to configure AI Agents: #{e.message}"
end
