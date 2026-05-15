class Api::V1::Accounts::Crm::DealConversationsController < Api::V1::Accounts::BaseController
  before_action :set_deal_conversation, only: [:destroy]

  def index
    @deal_conversations = current_account.conversations.joins(:deal_conversations).distinct
    render json: @deal_conversations
  end

  def create
    @deal = current_account.crm_deals.find(deal_conversation_params[:crm_deal_id])
    @conversation = current_account.conversations.find(deal_conversation_params[:conversation_id])

    @deal_conversation = DealConversation.new(deal_conversation_params)
    if @deal_conversation.save
      render json: @deal_conversation, status: :created
    else
      render json: { errors: @deal_conversation.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @deal_conversation.destroy
    head :no_content
  end

  private

  def set_deal_conversation
    @deal_conversation = DealConversation.find(params[:id])
  end

  def deal_conversation_params
    params.require(:deal_conversation).permit(:crm_deal_id, :conversation_id)
  end
end
