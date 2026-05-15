module AiAgents
  # Aggregates AiAgentLog data for a period and uses OpenAI to produce
  # a human-readable WhatsApp report message.
  class ReportGeneratorService
    def initialize(account, config)
      @account = account
      @config  = config
    end

    def generate
      logs = logs_for_period

      metrics = build_metrics(logs)
      prompt  = build_prompt(metrics)

      call_openai(prompt)
    rescue StandardError => e
      Rails.logger.error("[AiAgents::Report] Failed to generate report for account #{@account.id}: #{e.message}")
      fallback_report(build_metrics(logs_for_period))
    end

    private

    def period_range
      case @config.frequency
      when 'daily'   then 24.hours.ago..Time.current
      when 'weekly'  then 7.days.ago..Time.current
      when 'monthly' then 30.days.ago..Time.current
      else 24.hours.ago..Time.current
      end
    end

    def period_label
      case @config.frequency
      when 'daily'   then 'últimas 24 horas'
      when 'weekly'  then 'últimos 7 dias'
      when 'monthly' then 'últimos 30 dias'
      end
    end

    def logs_for_period
      AiAgentLog.where(account_id: @account.id, created_at: period_range)
    end

    def build_metrics(logs)
      total        = logs.count
      conversations = logs.pluck(:conversation_id).uniq.count
      successes    = logs.where(status: :success).count
      errors       = logs.where(status: :error).count
      handoffs     = logs.where(action: 'agent_paused').count
      tool_logs    = logs.where(action: 'tool_executed')

      {
        period:            period_label,
        conversations:     conversations,
        messages_processed: total,
        success_rate:      total > 0 ? (successes.to_f / total * 100).round(1) : 0,
        errors:            errors,
        handoff_count:     handoffs,
        handoff_rate:      conversations > 0 ? (handoffs.to_f / conversations * 100).round(1) : 0,
        tools_used:        tool_logs.count,
        top_tools:         top_tools(tool_logs)
      }
    end

    def top_tools(tool_logs)
      tool_logs.filter_map { |l| l.payload&.dig('tool_name') }
               .tally
               .sort_by { |_, v| -v }
               .first(3)
               .map { |name, count| "#{name} (#{count}x)" }
               .join(', ')
    end

    def build_prompt(metrics)
      lines = []
      lines << @config.custom_prompt.presence || default_system_prompt
      lines << "\nDados do período (#{metrics[:period]}):"
      lines << "- Conversas atendidas: #{metrics[:conversations]}" if @config.include_conversation_count
      lines << "- Mensagens processadas: #{metrics[:messages_processed]}" if @config.include_agent_stats
      lines << "- Taxa de sucesso: #{metrics[:success_rate]}%" if @config.include_agent_stats
      lines << "- Erros: #{metrics[:errors]}" if @config.include_agent_stats
      lines << "- Handoffs para humano: #{metrics[:handoff_count]} (#{metrics[:handoff_rate]}% das conversas)" if @config.include_handoff_rate
      if @config.include_tool_usage && metrics[:tools_used] > 0
        lines << "- Ferramentas usadas: #{metrics[:tools_used]}x"
        lines << "  Mais usadas: #{metrics[:top_tools]}" if metrics[:top_tools].present?
      end
      lines << "\nGere um relatório curto e direto em formato WhatsApp (use emojis, seja objetivo, máximo 15 linhas)."
      lines.join("\n")
    end

    def default_system_prompt
      "Você é um assistente que gera relatórios de desempenho do agente de IA para o cliente. " \
        "Seja profissional, use linguagem simples e destaque pontos positivos e oportunidades de melhoria."
    end

    def call_openai(prompt)
      client   = OpenAI::Client.new
      response = client.chat(parameters: {
        model:    'gpt-4o-mini',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.5,
        max_tokens:  600
      })
      response.dig('choices', 0, 'message', 'content') || fallback_report({})
    end

    def fallback_report(metrics)
      lines = ["📊 *Relatório StarSales AI* — #{metrics[:period]}"]
      lines << "✅ Conversas: #{metrics[:conversations]}" if metrics[:conversations]
      lines << "💬 Mensagens: #{metrics[:messages_processed]}" if metrics[:messages_processed]
      lines << "🤝 Handoffs: #{metrics[:handoff_count]}" if metrics[:handoff_count]
      lines.join("\n")
    end
  end
end
