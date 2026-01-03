class CreateInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :invites do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.string :recipient_email, null: false
      t.string :token, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invites, :token, unique: true
    add_index :invites, [ :sender_id, :recipient_email ], unique: true
  end
end
