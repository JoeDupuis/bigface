class CallTimeoutJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return unless call&.ringing?

    call.timeout!
  end
end
