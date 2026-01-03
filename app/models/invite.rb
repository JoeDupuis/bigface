class Invite < ApplicationRecord
  belongs_to :sender, class_name: "User"

  validates :recipient_email, presence: true
  validates :recipient_email, uniqueness: {
    scope: :sender_id,
    conditions: -> { pending }
  }
  validate :cannot_invite_self
  validate :cannot_invite_existing_contact

  normalizes :recipient_email, with: ->(e) { e.strip.downcase }

  before_create :generate_token

  scope :pending, -> { where(accepted_at: nil, declined_at: nil) }

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def cannot_invite_self
    return if sender.nil? || recipient_email.blank?
    if sender.email_address == recipient_email
      errors.add(:recipient_email, "can't invite yourself")
    end
  end

  def cannot_invite_existing_contact
    return if sender.nil? || recipient_email.blank?
    recipient = User.find_by(email_address: recipient_email)
    return unless recipient
    if Contact.exists?(user: sender, contact: recipient)
      errors.add(:recipient_email, "already a contact")
    end
  end
end
