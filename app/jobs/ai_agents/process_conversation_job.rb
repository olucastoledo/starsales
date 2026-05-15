module AiAgents
  class ProcessConversationJob < MutexApplicationJob
    queue_as :low
    # Do not retry automatically — if it fails, the user can send another message.
    # Retrying could cause duplicate or out-of-order responses.
    discard_on StandardError

    def perform(account_id, conversation_id)
      with_lock("ai_agent:conversation:#{conversation_id}") do
        process_conversation(account_id, conversation_id)
      end
    rescue MutexApplicationJob::LockAcquisitionError
      # Another job is already processing this conversation — that job will
      # pick up any messages that arrived while it held the lock.
      Rails.logger.info("[AiAgents] Conversation #{conversation_id} already being processed, skipping")
    end

    private

    def process_conversation(account_id, conversation_id)
      conversation = Conversation.find_by(id: conversation_id, account_id: account_id)
      return unless conversation

      agent_manager = AiAgents::AgentManager.for_conversation(conversation)
      return unless agent_manager

      pending = collect_pending_messages(conversation)
      return if pending.empty?

      executor = AiAgents::AgentExecutor.new(conversation, agent_manager.agent, pending)
      result = executor.execute

      send_agent_response(conversation, result) if result.present?
    end

    # Returns all incoming messages that arrived after the agent's last reply.
    # If the agent has never replied, returns all incoming messages.
    # Multiple burst messages are joined so the LLM sees them as one user turn.
    def collect_pending_messages(conversation)
      last_agent_at = conversation.messages
                                  .outgoing
                                  .order(created_at: :desc)
                                  .pick(:created_at)

      scope = conversation.messages.incoming.chat.order(created_at: :asc)
      scope = scope.where('created_at > ?', last_agent_at) if last_agent_at

      scope.filter_map { |m| m.content.presence }
    end

    def send_agent_response(conversation, result)
      content = result[:response]
      return if content.blank?

      Messages::MessageBuilder.new(nil, conversation, {
        content: content,
        message_type: 'outgoing',
        content_type: :text
      }).perform
    end
  end
end
