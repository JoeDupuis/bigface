class CallsController < ApplicationController
  before_action :set_call, only: %i[show]

  def index
    @calls = current_user_calls.order(created_at: :desc)
  end

  def create
    @call = Current.session.user.outgoing_calls.build(call_params)

    if @call.save
      redirect_to @call
    else
      head :unprocessable_entity
    end
  end

  def show
    if @call.nil? || !participant?
      head :not_found
      nil
    end
  end

  private

  def set_call
    @call = Call.find_by(id: params[:id])
  end

  def call_params
    params.require(:call).permit(:recipient_id)
  end

  def participant?
    current_user = Current.session.user
    @call.caller == current_user || @call.recipient == current_user
  end

  def current_user_calls
    user = Current.session.user
    Call.where(caller: user)
        .or(Call.where(recipient: user))
        .where.not(status: :ringing)
  end
end
