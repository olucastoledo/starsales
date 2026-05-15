module AiAgents
  class AgentExecutor
    # @param conversation  [Conversation]
    # @param ai_agent      [AiAgent]
    # @param pending       [Array<String>] one or more incoming messages to process together
    def initialize(conversation, ai_agent, pending)
      @conversation = conversation
      @ai_agent     = ai_agent
      @pending      = Array(pending).map(&:strip).reject(&:blank?)
    end

    def execute
      state = AiAgentConversationState.find_by(conversation_id: @conversation.id, ai_agent_id: @ai_agent.id)
      return nil if state&.paused?
      return nil unless @ai_agent.enabled?
      return nil if @pending.empty?

      agent_config = AgentManager.new(@ai_agent).load_agent_config
      result = call_openai(agent_config)
      log_success(result)
      result
    rescue StandardError => e
      log_error(e)
      nil
    end

    private

    # -------------------------------------------------------------------------
    # Context window
    # -------------------------------------------------------------------------

    # Returns messages that happened BEFORE the current pending batch.
    # This is the conversation history the agent uses for memory.
    def conversation_history
      # Find when the last agent reply was sent
      last_agent_at = @conversation.messages
                                   .outgoing
                                   .order(created_at: :desc)
                                   .pick(:created_at)

      scope = @conversation.messages.chat.order(created_at: :asc)

      # Only include messages up to (and including) the last agent response.
      # Pending messages (after last_agent_at) are the current user turn — added separately.
      scope = scope.where('created_at <= ?', last_agent_at) if last_agent_at

      scope.last(@ai_agent.context_window_messages).filter_map do |msg|
        next if msg.content.blank?

        { role: msg.outgoing? ? 'assistant' : 'user', content: msg.content }
      end
    end

    # -------------------------------------------------------------------------
    # OpenAI call
    # -------------------------------------------------------------------------

    def call_openai(agent_config)
      client   = OpenAI::Client.new
      messages = build_messages(agent_config)
      tools    = build_tools_schema(agent_config)
      tools_used = []

      loop do
        params = {
          model:       agent_config[:model],
          messages:    messages,
          temperature: agent_config[:temperature]
        }
        params[:tools]       = tools       if tools.any?
        params[:tool_choice] = 'auto'      if tools.any?

        response      = client.chat(parameters: params)
        choice        = response.dig('choices', 0)
        finish_reason = choice&.dig('finish_reason')

        if finish_reason == 'tool_calls'
          handle_tool_calls(choice, messages, tools_used)
        else
          content = choice&.dig('message', 'content') || ''
          return {
            response:    content,
            tools_used:  tools_used,
            model:       agent_config[:model],
            tokens_used: response.dig('usage', 'total_tokens')
          }
        end
      end
    end

    # Build the message array sent to the OpenAI chat endpoint.
    #
    # Structure:
    #   [ system ]
    #   [ ...conversation history (user/assistant alternating) ]
    #   [ user: combined pending messages ]
    #
    def build_messages(agent_config)
      msgs = [{ role: 'system', content: agent_config[:system_prompt] }]

      conversation_history.each { |m| msgs << m }

      # Combine burst messages into a single user turn so the LLM sees them together.
      user_turn = @pending.join("\n")
      msgs << { role: 'user', content: user_turn }

      msgs
    end

    # -------------------------------------------------------------------------
    # Tools
    # -------------------------------------------------------------------------

    def build_tools_schema(agent_config)
      (agent_config[:tools] || []).map do |tool|
        {
          type: 'function',
          function: {
            name:        tool[:name],
            description: tool[:description],
            parameters:  tool[:schema] || { type: 'object', properties: {} }
          }
        }
      end
    end

    def handle_tool_calls(choice, messages, tools_used)
      assistant_message = choice['message']
      messages << {
        role:       'assistant',
        content:    assistant_message['content'],
        tool_calls: assistant_message['tool_calls']
      }

      (assistant_message['tool_calls'] || []).each do |tool_call|
        tool_name   = tool_call['function']['name']
        tool_input  = JSON.parse(tool_call['function']['arguments'])
        tool_result = execute_tool(tool_name, tool_input)
        tools_used << { name: tool_name, result: tool_result }

        messages << {
          role:        'tool',
          tool_call_id: tool_call['id'],
          content:     tool_result.to_json
        }
      end
    rescue JSON::ParserError => e
      Rails.logger.error("[AiAgents] Tool call JSON parse error: #{e.message}")
    end

    def execute_tool(tool_name, params)
      class_name = "AiAgents::Tools::#{tool_name.classify}"
      tool_class = class_name.constantize
      tool_class.new.execute(params)
    rescue NameError
      { success: false, error: "Unknown tool: #{tool_name}" }
    rescue StandardError => e
      { success: false, error: e.message }
    end

    # -------------------------------------------------------------------------
    # Logging
    # -------------------------------------------------------------------------

    def log_success(result)
      AiAgentLog.log_action(
        @conversation.account_id, @conversation.id, @ai_agent.id,
        'agent_executed',
        { tokens_used: result[:tokens_used], tools_used: result[:tools_used], pending_count: @pending.size }
      )
    end

    def log_error(error)
      AiAgentLog.log_action(
        @conversation.account_id, @conversation.id, @ai_agent.id,
        'agent_execution_failed', {}, error.message
      )
    end
  end
end
