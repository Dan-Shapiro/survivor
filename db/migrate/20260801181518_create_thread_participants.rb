class CreateThreadParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :thread_participants do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.references :season_membership, null: false, foreign_key: true
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :thread_participants, [ :message_thread_id, :season_membership_id ], unique: true, name: "index_thread_participants_on_thread_and_membership"
  end
end
