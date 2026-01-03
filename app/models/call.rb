class Call < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :caller, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :answered_by_session, class_name: "Session", optional: true

  enum :status, { ringing: "ringing", active: "active", ended: "ended", missed: "missed", declined: "declined" }

  validates :caller_id, uniqueness: { scope: :status, conditions: -> { ringing }, message: "already has a ringing call" }
  validate :caller_and_recipient_are_contacts

  def answer!(session)
    raise InvalidTransition unless ringing?
    update!(status: :active, started_at: Time.current, answered_by_session: session)
  end

  def end!
    raise InvalidTransition unless active?
    update!(status: :ended, ended_at: Time.current)
  end

  def decline!
    raise InvalidTransition unless ringing?
    update!(status: :declined, ended_at: Time.current)
  end

  def miss!
    raise InvalidTransition unless ringing?
    update!(status: :missed, ended_at: Time.current)
  end

  private

  def caller_and_recipient_are_contacts
    return if caller_id.blank? || recipient_id.blank?
    return if Contact.exists?(user_id: caller_id, contact_id: recipient_id)
    errors.add(:recipient, "must be a contact")
  end
end
