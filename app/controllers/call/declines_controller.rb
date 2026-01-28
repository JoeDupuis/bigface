class Call::DeclinesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    @call = Call.find_by(id: params[:call_id])
    return head :not_found unless @call
    return head :forbidden unless recipient?

    @call.decline!
    redirect_to contacts_path
  rescue Call::InvalidTransition
    head :unprocessable_entity
  end

  private

  def recipient?
    Current.session.user == @call.recipient
  end
end
