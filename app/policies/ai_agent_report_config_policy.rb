class AiAgentReportConfigPolicy < ApplicationPolicy
  def index?   = administrator?
  def show?    = administrator?
  def create?  = administrator?
  def update?  = administrator?
  def destroy? = administrator?
  def send_now? = administrator?

  private

  def administrator?
    @account_user&.administrator?
  end
end
