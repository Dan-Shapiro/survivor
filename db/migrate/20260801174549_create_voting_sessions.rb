class CreateVotingSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :voting_sessions do |t|
      t.references :round, null: false, foreign_key: true
      t.integer :session_number, null: false
      t.jsonb :eligible_voter_ids, null: false, default: []
      t.jsonb :candidate_ids, null: false, default: []
      t.string :status, null: false, default: "open"
      t.datetime :opened_at
      t.datetime :closed_at

      t.timestamps
    end

    add_index :voting_sessions, [ :round_id, :session_number ], unique: true
  end
end
