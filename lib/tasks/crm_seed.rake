# CRM Pipeline Seed Task
#
# Creates a realistic CRM pipeline with stages and links existing conversations to it.
# Also creates sample conversations if no conversations exist yet.
#
# Usage:
#   ACCOUNT_ID=1 bundle exec rake crm:seed
#   ACCOUNT_ID=1 PIPELINE_NAME="Vendas WhatsApp" bundle exec rake crm:seed
#   ACCOUNT_ID=1 RESET=true bundle exec rake crm:seed  # removes existing CRM data first
#
# rubocop:disable Metrics/BlockLength, Rails/Output
namespace :crm do
  desc 'Seed CRM pipeline with realistic conversation data for testing'
  task seed: :environment do
    unless Rails.env.development?
      puts 'This task can only be run in the development environment.'
      exit(1)
    end

    account_id = ENV.fetch('ACCOUNT_ID', nil)
    if account_id.blank?
      puts 'Error: ACCOUNT_ID is required'
      puts 'Usage: ACCOUNT_ID=1 bundle exec rake crm:seed'
      exit(1)
    end

    account = Account.find_by(id: account_id)
    unless account
      puts "Error: Account #{account_id} not found"
      exit(1)
    end

    puts "\n=== CRM Seed for Account: #{account.name} ==="

    # Optionally reset CRM data
    if ENV['RESET'] == 'true'
      puts '→ Resetting existing CRM data...'
      conn = ActiveRecord::Base.connection
      # Delete in FK-safe order using raw SQL to avoid AR cascade issues
      conn.execute('DELETE FROM deal_conversations')
      conn.execute('DELETE FROM crm_deals')
      conn.execute('DELETE FROM crm_stages')
      conn.execute('DELETE FROM crm_pipelines')
      puts '  ✓ CRM data cleared'
    end

    pipeline_name = ENV.fetch('PIPELINE_NAME', 'Vendas & Suporte')

    # -------------------------------------------------------------------------
    # 1. Create Pipeline
    # -------------------------------------------------------------------------
    pipeline = account.crm_pipelines.find_or_create_by!(name: pipeline_name) do |p|
      p.description = 'Pipeline gerado automaticamente para testes'
    end
    puts "\n→ Pipeline: \"#{pipeline.name}\" (id: #{pipeline.id})"

    # -------------------------------------------------------------------------
    # 2. Create Stages
    # -------------------------------------------------------------------------
    stage_names = ['Novo Lead', 'Em Atendimento', 'Proposta Enviada', 'Fechado']
    stages = stage_names.each_with_index.map do |name, idx|
      stage = pipeline.stages.find_or_create_by!(name: name) do |s|
        s.position = idx
      end
      puts "  ✓ Estágio: #{name}"
      stage
    end

    # -------------------------------------------------------------------------
    # 3. Ensure there are conversations to link
    # -------------------------------------------------------------------------
    inbox = account.inboxes.first
    unless inbox
      puts "\n⚠  Nenhum inbox encontrado. Crie um inbox primeiro (WhatsApp, Instagram, etc.)"
      puts '   Você pode criar um em: Configurações → Inboxes → Novo Inbox'
      exit(0)
    end

    puts "\n→ Usando inbox: \"#{inbox.name}\" (#{inbox.channel_type})"

    existing_conversations = account.conversations.open.limit(20)

    if existing_conversations.count < 4
      puts '→ Poucas conversas encontradas. Criando conversas de exemplo...'

      contacts_data = [
        { name: 'Maria Silva',    phone: '+5511999001001', email: 'maria.silva@exemplo.com' },
        { name: 'João Santos',    phone: '+5511999002002', email: 'joao.santos@exemplo.com' },
        { name: 'Ana Oliveira',   phone: '+5511999003003', email: 'ana.oliveira@exemplo.com' },
        { name: 'Carlos Pereira', phone: '+5511999004004', email: 'carlos.pereira@exemplo.com' },
        { name: 'Lucia Ferreira', phone: '+5511999005005', email: 'lucia.ferreira@exemplo.com' },
        { name: 'Pedro Costa',    phone: '+5511999006006', email: 'pedro.costa@exemplo.com' },
        { name: 'Fernanda Lima',  phone: '+5511999007007', email: 'fernanda.lima@exemplo.com' },
        { name: 'Ricardo Souza',  phone: '+5511999008008', email: 'ricardo.souza@exemplo.com' },
      ]

      sample_messages = [
        'Olá, gostaria de saber mais sobre os produtos.',
        'Boa tarde! Vocês têm disponibilidade para atendimento hoje?',
        'Quero fazer um orçamento, por favor.',
        'Recebi uma proposta de vocês e tenho algumas dúvidas.',
        'Preciso de ajuda com meu pedido.',
        'Vim pelo Instagram, vi o produto e quero mais informações.',
        'Qual o prazo de entrega para minha região?',
        'Pode me enviar o catálogo completo?',
      ]

      agent = account.users.first

      contacts_data.each_with_index do |cd, i|
        contact = account.contacts.find_or_create_by!(phone_number: cd[:phone]) do |c|
          c.name  = cd[:name]
          c.email = cd[:email]
        end

        contact_inbox = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) do |ci|
          ci.source_id = "crm_seed_#{account_id}_#{i}_#{Time.now.to_i}"
        end

        conversation = Conversation.create!(
          account: account,
          inbox: inbox,
          contact: contact,
          contact_inbox: contact_inbox,
          status: [:open, :open, :pending].sample,
          assignee: agent
        )

        Message.create!(
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: contact,
          content: sample_messages[i % sample_messages.length],
          message_type: :incoming,
          content_type: :text
        )

        if [true, false].sample
          Message.create!(
            account: account,
            inbox: inbox,
            conversation: conversation,
            sender: agent,
            content: 'Olá! Obrigado pelo contato. Em que posso ajudar?',
            message_type: :outgoing,
            content_type: :text
          )
        end

        puts "  ✓ Conversa criada: #{contact.name}"
      end

      existing_conversations = account.conversations.open.limit(20)
    end

    # -------------------------------------------------------------------------
    # 4. Link conversations to deals in pipeline stages
    # -------------------------------------------------------------------------
    puts "\n→ Vinculando conversas ao pipeline..."

    conversations = existing_conversations.to_a.first(12)
    conversations_per_stage = (conversations.length.to_f / stages.length).ceil

    conversations.each_with_index do |conv, idx|
      # Skip if already linked to a deal in this pipeline
      existing = DealConversation.joins(crm_deal: :crm_stage)
                                 .where(conversation: conv)
                                 .where(crm_stages: { crm_pipeline_id: pipeline.id })
                                 .exists?
      next if existing

      stage = stages[idx / [conversations_per_stage, 1].max] || stages.last

      deal = account.crm_deals.create!(
        crm_stage: stage,
        name: conv.contact&.name || "Conversa ##{conv.id}",
        status: 0
      )

      DealConversation.create!(crm_deal: deal, conversation: conv)
      puts "  ✓ \"#{deal.name}\" → #{stage.name}"
    end

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------
    puts "\n=== ✅ CRM Seed completo! ==="
    puts "   Pipeline : #{pipeline.name}"
    puts "   Estágios : #{stages.map(&:name).join(', ')}"
    puts "   Deals    : #{pipeline.deals.count}"
    puts "\n   Acesse: /app/accounts/#{account_id}/crm\n\n"
  end
end
# rubocop:enable Metrics/BlockLength, Rails/Output
