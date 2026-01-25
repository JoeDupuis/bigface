class CallChannel < ApplicationCable::Channel
  def subscribed
    @call = Call.find(params[:call_id])
    if authorized? && (@call.ringing? || @call.active?)
      stream_for @call
    else
      reject
    end
  end

  def unsubscribed
    @call&.reload&.hangup!
  rescue ActiveRecord::RecordNotFound
  end

  def receive(data)
    CallChannel.broadcast_to(@call, data.merge("from" => current_user.id))
  end

  private

  def authorized?
    @call.caller_id == current_user.id || @call.recipient_id == current_user.id
  end
end
