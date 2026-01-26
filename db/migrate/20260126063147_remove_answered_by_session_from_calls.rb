class RemoveAnsweredBySessionFromCalls < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :calls, :sessions, column: :answered_by_session_id
    remove_column :calls, :answered_by_session_id, :integer
  end
end
