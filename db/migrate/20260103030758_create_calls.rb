class CreateCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :calls do |t|
      t.references :caller, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "ringing"
      t.datetime :started_at
      t.datetime :ended_at
      t.references :answered_by_session, foreign_key: { to_table: :sessions }

      t.timestamps
    end

    add_index :calls, :status
  end
end
