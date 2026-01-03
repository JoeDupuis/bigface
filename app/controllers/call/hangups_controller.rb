class Call::HangupsController < ApplicationController
  def create
    @call = Call.find_by(id: params[:call_id])
    return head :not_found unless @call
    return head :not_found unless participant?

    @call.hangup!
    redirect_to contacts_path
  end

  private

  def participant?
    current_user = Current.session.user
    @call.caller == current_user || @call.recipient == current_user
  end
end
