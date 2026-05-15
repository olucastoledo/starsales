module AiAgents
  class AgentManager
    attr_reader :agent

    def initialize(agent)
      @agent = agent
    end

    def load_agent_config
      {
        id: @agent.id,
        name: @agent.name,
        personality: @agent.personality,
        model: @agent.model,
        temperature: @agent.temperature,
        system_prompt: @agent.system_prompt,
        tools: load_tools
      }
    end

    def load_tools
      @agent.ai_agent_tools.enabled.map do |tool|
        {
          id: tool.id,
          name: tool.name,
          description: tool.description,
          schema: tool.schema,
          endpoint_url: tool.endpoint_url,
          auth_config: tool.auth_config
        }
      end
    end

    def self.for_account_and_personality(account_id, personality)
      agent = AiAgent.where(account_id: account_id, personality: personality).enabled.first
      new(agent) if agent.present?
    end

    def self.for_conversation(conversation)
      state = AiAgentConversationState.active.find_by(conversation_id: conversation.id)
      return nil unless state

      agent = state.ai_agent
      return nil unless agent&.enabled?

      new(agent)
    end
  end
end
