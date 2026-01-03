class Call::AnswersController < ApplicationController
  def create
    @call = Call.find_by(id: params[:call_id])
    return head :not_found unless @call
    return head :forbidden unless recipient?

    @call.answer!(Current.session)
    redirect_to @call
  rescue Call::InvalidTransition
    head :unprocessable_entity
  end

  private

  def recipient?
    Current.session.user == @call.recipient
  end
end
