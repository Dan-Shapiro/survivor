class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :voting_session, null: false, foreign_key: true
      t.references :voter_membership, null: false, foreign_key: { to_table: :season_memberships }
      t.references :voted_for_membership, null: false, foreign_key: { to_table: :season_memberships }

      t.timestamps
    end

    add_index :votes, [ :voting_session_id, :voter_membership_id ], unique: true, name: "index_votes_on_session_and_voter"
  end
end
