class Api::V1::Accounts::Crm::StagesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline
  before_action :set_stage, only: [:update, :destroy]

  def reorder
    ids = Array(params[:stage_ids]).map(&:to_i)
    ids.each_with_index do |stage_id, position|
      @pipeline.stages.find_by(id: stage_id)&.update_column(:position, position)
    end
    head :ok
  end

  def index
    @stages = @pipeline.stages.ordered
    render json: @stages
  end

  def create
    @stage = @pipeline.stages.build(stage_params)
    @stage.position = @pipeline.stages.count if @stage.position.blank?

    if @stage.save
      render json: @stage, status: :created
    else
      render json: { errors: @stage.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @stage.update(stage_params)
      render json: @stage
    else
      render json: { errors: @stage.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @stage.destroy
    head :no_content
  end

  private

  def set_pipeline
    @pipeline = current_account.crm_pipelines.find(params[:pipeline_id])
  end

  def set_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def stage_params
    params.require(:crm_stage).permit(:name, :description, :position, :show_value_sum)
  end
end
