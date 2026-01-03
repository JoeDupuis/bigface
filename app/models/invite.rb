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

  def self.pending_for(user)
    pending.where(recipient_email: user.email_address)
  end

  def accept!(user)
    transaction do
      update!(accepted_at: Time.current)
      Contact.create!(user: sender, contact: user)
      Contact.create!(user: user, contact: sender)
    end
  end

  def accepted?
    accepted_at.present?
  end

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
