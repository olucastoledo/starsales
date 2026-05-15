module AiAgents
  class PauseService
    def initialize(conversation, ai_agent)
      @conversation = conversation
      @ai_agent = ai_agent
    end

    def pause!(paused_by: 'human', reason: nil)
      state = find_or_create_state
      state.pause!(paused_by: paused_by, reason: reason)
      log_pause_action(paused_by, reason)
      state
    end

    def resume!
      state = find_or_create_state
      state.resume!
      log_resume_action
      state
    end

    def paused?
      find_or_create_state.paused?
    end

    private

    def find_or_create_state
      AiAgentConversationState.find_or_create_by(
        account_id: @conversation.account_id,
        conversation_id: @conversation.id,
        ai_agent_id: @ai_agent.id
      )
    end

    def log_pause_action(paused_by, reason)
      AiAgentLog.log_action(
        @conversation.account_id,
        @conversation.id,
        @ai_agent.id,
        'paused',
        { paused_by: paused_by, reason: reason }
      )
    end

    def log_resume_action
      AiAgentLog.log_action(
        @conversation.account_id,
        @conversation.id,
        @ai_agent.id,
        'resumed',
        {}
      )
    end
  end
end
