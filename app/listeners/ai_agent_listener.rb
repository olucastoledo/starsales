class AiAgentListener < BaseListener
  DEFAULT_DEBOUNCE_DELAY = 5.seconds

  # New conversation on an inbox that has an AI agent → create active state
  def conversation_created(event)
    conversation = event.data[:conversation]
    return unless conversation

    inbox_ai_agent = InboxAiAgent.find_by(inbox_id: conversation.inbox_id, enabled: true)
    return unless inbox_ai_agent

    AiAgentConversationState.find_or_create_by!(
      conversation_id: conversation.id,
      ai_agent_id:     inbox_ai_agent.ai_agent_id
    ) do |state|
      state.account_id = conversation.account_id
    end
  end

  # Incoming message on an active AI agent conversation → enqueue processing
  def message_created(event)
    message      = event.data[:message]
    conversation = message.conversation

    state = active_state_for(conversation, message)
    return unless state

    delay = state.ai_agent.debounce_delay_seconds.seconds
    AiAgents::ProcessConversationJob.set(wait: delay).perform_later(
      conversation.account_id,
      conversation.id
    )
  end

  # Human agent assigned → pause AI agent for that conversation
  def conversation_updated(event)
    conversation = event.data[:conversation]
    changes      = event.data[:changes]
    return unless conversation
    return unless changes&.key?('assignee_id')

    _, new_assignee_id = changes['assignee_id']
    return if new_assignee_id.blank?

    state = AiAgentConversationState.active.find_by(conversation_id: conversation.id)
    return unless state

    state.pause!(paused_by: 'human', reason: "Human agent assigned (id: #{new_assignee_id})")
  end

  private

  def active_state_for(conversation, message)
    return nil if message.private?
    return nil if message.activity?
    return nil unless message.incoming?

    AiAgentConversationState.active.includes(:ai_agent).find_by(conversation_id: conversation.id)
  end
end
