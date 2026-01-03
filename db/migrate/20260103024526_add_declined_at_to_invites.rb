class AddDeclinedAtToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :declined_at, :datetime

    remove_index :invites, [ :sender_id, :recipient_email ]
    add_index :invites, [ :sender_id, :recipient_email ],
      unique: true,
      where: "accepted_at IS NULL AND declined_at IS NULL",
      name: "index_invites_on_sender_and_email_pending"
  end
end
