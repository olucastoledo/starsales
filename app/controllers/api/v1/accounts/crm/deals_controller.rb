class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::BaseController
  before_action :set_deal, only: [:show, :update, :destroy]

  def index
    @deals = current_account.crm_deals.includes(crm_stage: :crm_pipeline, deal_conversation: :conversation)
    @deals = @deals.where(crm_stage_id: params[:stage_id]) if params[:stage_id].present?
    if params[:pipeline_id].present?
      stage_ids = current_account.crm_pipelines.find(params[:pipeline_id]).stages.pluck(:id)
      @deals = @deals.where(crm_stage_id: stage_ids)
    end
    if params[:conversation_id].present?
      conversation_ids = DealConversation.where(conversation_id: params[:conversation_id]).pluck(:crm_deal_id)
      @deals = @deals.where(id: conversation_ids)
    end
    render json: @deals.map { |d| serialize_deal_summary(d) }
  end

  def create
    conversation = resolve_conversation
    name = params.dig(:crm_deal, :name).presence ||
           conversation&.contact&.name.presence ||
           'Conversa sem nome'

    @deal = current_account.crm_deals.build(deal_params.merge(name: name))

    if @deal.save
      DealConversation.create!(crm_deal: @deal, conversation: conversation) if conversation
      render json: @deal, status: :created
    else
      render json: { errors: @deal.errors }, status: :unprocessable_entity
    end
  end

  def show
    render json: @deal
  end

  def update
    if @deal.update(deal_params)
      render json: @deal
    else
      render json: { errors: @deal.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @deal.destroy
    head :no_content
  end

  private

  def set_deal
    @deal = current_account.crm_deals.find(params[:id])
  end

  def resolve_conversation
    return nil if params[:conversation_id].blank?

    current_account.conversations.find_by(id: params[:conversation_id])
  end

  def deal_params
    params.require(:crm_deal).permit(:name, :description, :value, :expected_close_date, :crm_stage_id, :status)
  end

  def serialize_deal_summary(deal)
    stage    = deal.crm_stage
    pipeline = stage&.crm_pipeline
    {
      id: deal.id,
      name: deal.name,
      crm_stage_id: deal.crm_stage_id,
      stage_name: stage&.name,
      pipeline_id: pipeline&.id,
      pipeline_name: pipeline&.name
    }
  end
end
