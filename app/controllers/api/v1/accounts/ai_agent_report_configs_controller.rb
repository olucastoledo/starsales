class Api::V1::Accounts::AiAgentReportConfigsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_config, only: [:show, :update, :destroy, :send_now]

  def index
    configs = Current.account.ai_agent_report_configs.includes(:inbox).order(created_at: :desc)
    render json: configs.map { |c| serialize(c) }
  end

  def show
    render json: serialize(@config)
  end

  def create
    config = Current.account.ai_agent_report_configs.create!(config_params)
    render json: serialize(config), status: :created
  end

  def update
    @config.update!(config_params)
    render json: serialize(@config)
  end

  def destroy
    @config.destroy!
    head :no_content
  end

  # POST /send_now — trigger a report immediately (for testing)
  def send_now
    AiAgents::SendSingleReportJob.perform_later(@config.id)
    render json: { message: 'Report scheduled for immediate delivery' }
  end

  private

  def set_config
    @config = Current.account.ai_agent_report_configs.find(params[:id])
  end

  def config_params
    params.require(:ai_agent_report_config).permit(
      :inbox_id, :frequency, :send_hour, :send_day_of_week, :send_day_of_month,
      :whatsapp_number, :custom_prompt,
      :include_conversation_count, :include_agent_stats,
      :include_handoff_rate, :include_tool_usage, :enabled
    )
  end

  def check_authorization
    authorize(AiAgentReportConfig)
  end

  def serialize(config)
    {
      id:                        config.id,
      inbox_id:                  config.inbox_id,
      inbox_name:                config.inbox&.name,
      frequency:                 config.frequency,
      send_hour:                 config.send_hour,
      send_day_of_week:          config.send_day_of_week,
      send_day_of_month:         config.send_day_of_month,
      whatsapp_number:           config.whatsapp_number,
      custom_prompt:             config.custom_prompt,
      include_conversation_count: config.include_conversation_count,
      include_agent_stats:       config.include_agent_stats,
      include_handoff_rate:      config.include_handoff_rate,
      include_tool_usage:        config.include_tool_usage,
      enabled:                   config.enabled,
      last_sent_at:              config.last_sent_at
    }
  end
end
