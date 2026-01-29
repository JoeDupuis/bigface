class Call < ApplicationRecord
  class InvalidTransition < StandardError; end

  RING_TIMEOUT = Rails.env.test? ? 2.seconds : 30.seconds

  belongs_to :caller, class_name: "User"
  belongs_to :recipient, class_name: "User"

  enum :status, { ringing: "ringing", active: "active", ended: "ended", missed: "missed", declined: "declined" }

  validates :caller_id, uniqueness: { scope: :status, conditions: -> { ringing }, message: "already has a ringing call" }
  validate :caller_and_recipient_are_contacts

  broadcasts_refreshes_to :recipient

  after_create_commit :broadcast_to_recipient
  after_create_commit :send_push_notification_to_recipient
  after_create_commit :schedule_timeout

  def answer!(session)
    raise InvalidTransition unless ringing?
    update!(status: :active, started_at: Time.current)
    broadcast_answered(session.id)
  end

  def end!
    raise InvalidTransition unless active?
    update!(status: :ended, ended_at: Time.current)
  end

  def decline!
    raise InvalidTransition unless ringing?
    update!(status: :declined, ended_at: Time.current)
    broadcast_declined
  end

  def miss!
    raise InvalidTransition unless ringing?
    update!(status: :missed, ended_at: Time.current)
  end

  def timeout!
    return unless ringing?
    update!(status: :missed, ended_at: Time.current)
    broadcast_timeout
  end

  def hangup!
    case status
    when "ringing"
      update!(status: :ended, ended_at: Time.current)
      broadcast_cancellation
    when "active"
      update!(status: :ended, ended_at: Time.current)
      broadcast_hangup
    end
  end

  private

  def broadcast_to_recipient
    UserNotificationChannel.broadcast_to(recipient, {
      type: "incoming_call",
      call_id: id,
      caller_name: caller.name,
      caller_id: caller.id
    })
  end

  def broadcast_answered(session_id)
    UserNotificationChannel.broadcast_to(recipient, {
      type: "call_answered",
      call_id: id
    })
    CallChannel.broadcast_to(self, {
      type: "answered",
      answered_by: session_id
    })
    send_call_ended_push("answered")
  end

  def broadcast_declined
    CallChannel.broadcast_to(self, { type: "declined" })
  end

  def broadcast_timeout
    CallChannel.broadcast_to(self, { type: "timeout" })
    UserNotificationChannel.broadcast_to(recipient, {
      type: "call_timeout",
      call_id: id
    })
    send_call_ended_push("timeout")
  end

  def broadcast_hangup
    CallChannel.broadcast_to(self, { type: "hangup" })
  end

  def broadcast_cancellation
    UserNotificationChannel.broadcast_to(recipient, {
      type: "call_cancelled",
      call_id: id
    })
    send_call_ended_push("cancelled")
  end

  def schedule_timeout
    CallTimeoutJob.set(wait: RING_TIMEOUT).perform_later(id)
  end

  def caller_and_recipient_are_contacts
    return if caller_id.blank? || recipient_id.blank?
    return if Contact.exists?(user_id: caller_id, contact_id: recipient_id)
    errors.add(:recipient, "must be a contact")
  end

  def send_push_notification_to_recipient
    ApplicationPushNotification.silent.with_data(
      type: "incoming_call",
      call_id: id.to_s,
      caller_name: caller.name,
      caller_id: caller_id.to_s
    ).new.deliver_later_to(recipient.push_devices)
  end

  def send_call_ended_push(reason)
    ApplicationPushNotification.silent.with_data(
      type: "call_ended",
      call_id: id.to_s,
      reason: reason
    ).new.deliver_later_to(recipient.push_devices)
  end
end
