class Api::V1::Accounts::AiAgentToolsController < Api::V1::Accounts::BaseController
  before_action :ai_agent
  before_action :ai_agent_tool, except: [:index, :create]
  before_action :check_authorization

  def index
    @ai_agent_tools = @ai_agent.ai_agent_tools
  end

  def show; end

  def create
    @ai_agent_tool = @ai_agent.ai_agent_tools.create!(ai_agent_tool_params)
  end

  def update
    @ai_agent_tool.update!(ai_agent_tool_params)
  end

  def destroy
    @ai_agent_tool.destroy!
    head :ok
  end

  private

  def ai_agent
    @ai_agent ||= Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def ai_agent_tool
    @ai_agent_tool ||= @ai_agent.ai_agent_tools.find(params[:id])
  end

  def ai_agent_tool_params
    params.require(:ai_agent_tool).permit(
      :name, :description, :tool_type, :endpoint_url, :enabled,
      schema: {},
      auth_config: {}
    )
  end
end
