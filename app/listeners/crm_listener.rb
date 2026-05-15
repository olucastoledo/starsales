class CrmListener < BaseListener
  # When a new conversation arrives, automatically add it to the pipeline
  # configured for that inbox — if any.
  def conversation_created(event)
    conversation = event.data[:conversation]
    return unless conversation

    pipeline = conversation.inbox.default_crm_pipeline
    return unless pipeline

    stage = pipeline.stages.ordered.first
    return unless stage

    # Don't create a duplicate deal for this conversation
    return if DealConversation.exists?(conversation: conversation)

    ActiveRecord::Base.transaction do
      deal = conversation.account.crm_deals.create!(
        crm_stage: stage,
        name: conversation.contact&.name.presence || "Conversa ##{conversation.id}",
        status: :open
      )
      DealConversation.create!(crm_deal: deal, conversation: conversation)
    end
  rescue StandardError => e
    Rails.logger.error("[CRM] Auto-assign failed for conversation #{conversation&.id}: #{e.message}")
  end
end
