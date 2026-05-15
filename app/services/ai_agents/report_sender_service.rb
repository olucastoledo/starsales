module AiAgents
  # Finds or creates an outbound WhatsApp conversation to the configured number
  # and sends the generated report message.
  class ReportSenderService
    def initialize(account, config, message_content)
      @account = account
      @config  = config
      @content = message_content
    end

    def send!
      raise 'inbox_id is required' if @config.inbox_id.blank?
      raise 'whatsapp_number is required' if @config.whatsapp_number.blank?

      inbox   = @account.inboxes.find(@config.inbox_id)
      contact = find_or_create_contact(inbox)
      conversation = find_or_create_conversation(inbox, contact)

      Messages::MessageBuilder.new(nil, conversation, {
        content:      @content,
        message_type: 'outgoing',
        content_type: :text,
        private:      false
      }).perform

      @config.update!(last_sent_at: Time.current)
      Rails.logger.info("[AiAgents::Report] Report sent to #{@config.whatsapp_number} for account #{@account.id}")
    rescue StandardError => e
      Rails.logger.error("[AiAgents::Report] Failed to send report for account #{@account.id}: #{e.message}")
      raise
    end

    private

    def normalized_number
      # Ensure E.164 format: strip non-digits then add +
      digits = @config.whatsapp_number.gsub(/\D/, '')
      "+#{digits}"
    end

    def find_or_create_contact(inbox)
      contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id:   normalized_number,
        inbox:       inbox,
        contact_attributes: {
          name:  normalized_number,
          phone_number: normalized_number
        }
      ).perform
      contact_inbox.contact
    end

    def find_or_create_conversation(inbox, contact)
      contact_inbox = ContactInbox.find_by(inbox: inbox, contact: contact)

      # Reuse an open conversation if one exists, otherwise create fresh
      existing = contact_inbox&.conversations&.where(status: :open)&.order(created_at: :desc)&.first
      return existing if existing

      Conversation.create!(
        account_id:        @account.id,
        inbox_id:          inbox.id,
        contact_id:        contact.id,
        contact_inbox_id:  contact_inbox&.id,
        status:            :open,
        assignee_id:       nil
      )
    end
  end
end
