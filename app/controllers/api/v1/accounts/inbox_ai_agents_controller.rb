class Api::V1::Accounts::InboxAiAgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  # GET /api/v1/accounts/:account_id/inboxes/:inbox_id/ai_agent
  def show
    record = InboxAiAgent.find_by(inbox_id: @inbox.id)
    if record&.ai_agent
      render json: { ai_agent_id: record.ai_agent_id, enabled: record.enabled, agent: agent_summary(record.ai_agent) }
    else
      render json: { ai_agent_id: nil, enabled: false, agent: nil }
    end
  end

  # POST /api/v1/accounts/:account_id/inboxes/:inbox_id/ai_agent
  # body: { ai_agent_id: 123 }   — pass null/blank to disconnect
  def create
    ai_agent_id = params[:ai_agent_id].presence

    if ai_agent_id.blank?
      InboxAiAgent.where(inbox_id: @inbox.id).destroy_all
      render json: { ai_agent_id: nil, enabled: false, agent: nil }
      return
    end

    agent = Current.account.ai_agents.find(ai_agent_id)
    record = InboxAiAgent.find_or_initialize_by(inbox_id: @inbox.id)
    record.ai_agent = agent
    record.enabled  = true
    record.save!

    render json: { ai_agent_id: record.ai_agent_id, enabled: record.enabled, agent: agent_summary(agent) }
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize(@inbox, :show?)
  end

  def agent_summary(agent)
    { id: agent.id, name: agent.name, personality: agent.personality, model: agent.model }
  end
end
