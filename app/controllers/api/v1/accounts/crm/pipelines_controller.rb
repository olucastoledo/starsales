class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline, only: [:show, :update, :destroy, :assign_inboxes]

  def index
    @pipelines = current_account.crm_pipelines.includes(:stages, :inboxes)
    render json: @pipelines.map { |p|
      {
        id: p.id,
        name: p.name,
        description: p.description,
        assigned_inbox_ids: p.inboxes.map(&:id),
        stages: p.stages.map { |s| { id: s.id, name: s.name, position: s.position, show_value_sum: s.show_value_sum } }
      }
    }
  end

  def create
    @pipeline = current_account.crm_pipelines.build(pipeline_params)
    if @pipeline.save
      render json: @pipeline, status: :created
    else
      render json: { errors: @pipeline.errors }, status: :unprocessable_entity
    end
  end

  def show
    stages = @pipeline.stages.ordered
    deals = @pipeline.deals
                     .includes(:crm_stage, deal_conversation: { conversation: [:contact, :inbox] })

    render json: {
      id: @pipeline.id,
      name: @pipeline.name,
      description: @pipeline.description,
      assigned_inbox_ids: @pipeline.inboxes.pluck(:id),
      stages: stages.map { |s| { id: s.id, name: s.name, position: s.position, show_value_sum: s.show_value_sum } },
      deals: deals.map { |d| serialize_deal(d) }
    }
  end

  def update
    if @pipeline.update(pipeline_params)
      render json: @pipeline
    else
      render json: { errors: @pipeline.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @pipeline.destroy
    head :no_content
  end

  # PATCH /crm/pipelines/:id/assign_inboxes
  # Body: { inbox_ids: [1, 2, 3] }
  # Sets these inboxes to auto-route new conversations into this pipeline.
  # Inboxes not in the list are detached.
  def assign_inboxes
    inbox_ids = Array(params[:inbox_ids]).map(&:to_i)

    # Detach inboxes currently pointing to this pipeline that are not in new list
    current_account.inboxes
                   .where(default_crm_pipeline: @pipeline)
                   .where.not(id: inbox_ids)
                   .update_all(default_crm_pipeline_id: nil)

    # Attach new inboxes
    current_account.inboxes
                   .where(id: inbox_ids)
                   .update_all(default_crm_pipeline_id: @pipeline.id)

    render json: { assigned_inbox_ids: @pipeline.reload.inboxes.pluck(:id) }
  end

  private

  def set_pipeline
    @pipeline = current_account.crm_pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:crm_pipeline).permit(:name, :description)
  end

  def serialize_deal(deal)
    conv    = deal.conversation
    contact = conv&.contact
    inbox   = conv&.inbox

    {
      id: deal.id,
      crm_stage_id: deal.crm_stage_id,
      status: deal.status,
      conversation_id: conv&.id,
      contact_name: contact&.name.presence || conv&.meta&.dig('sender', 'name') || deal.name,
      contact_id: contact&.id,
      contact_avatar: contact&.avatar_url,
      inbox_name: inbox&.name,
      channel_type: inbox&.channel_type,
      last_activity_at: conv&.last_activity_at,
      conversation_status: conv&.status,
      unread_count: conv ? conv.unread_incoming_messages.count : 0,
      value: deal.value
    }
  end
end
