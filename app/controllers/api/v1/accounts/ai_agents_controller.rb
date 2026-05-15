class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :ai_agent, except: [:index, :create]
  before_action :check_authorization

  def index
    @ai_agents = Current.account.ai_agents.includes(:ai_agent_tools)
  end

  def show; end

  def create
    @ai_agent = Current.account.ai_agents.create!(ai_agent_params)
  end

  def update
    @ai_agent.update!(ai_agent_params)
  end

  def destroy
    @ai_agent.destroy!
    head :ok
  end

  private

  def ai_agent
    @ai_agent ||= Current.account.ai_agents.find(params[:id])
  end

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name, :description, :personality, :system_prompt, :temperature, :model, :enabled,
      :debounce_delay_seconds, :context_window_messages,
      custom_attributes: {}
    )
  end
end
