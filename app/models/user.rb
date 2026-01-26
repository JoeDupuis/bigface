class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :push_devices, class_name: "ApplicationPushDevice", as: :owner, dependent: :destroy
  has_many :sent_invites, class_name: "Invite", foreign_key: :sender_id, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :contact_users, through: :contacts, source: :contact
  has_many :outgoing_calls, class_name: "Call", foreign_key: :caller_id, dependent: :destroy
  has_many :incoming_calls, class_name: "Call", foreign_key: :recipient_id, dependent: :destroy

  validates :name, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
