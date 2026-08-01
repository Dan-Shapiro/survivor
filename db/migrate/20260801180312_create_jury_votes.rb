class CreateJuryVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :jury_votes do |t|
      t.references :season, null: false, foreign_key: true
      t.references :juror_membership, null: false, foreign_key: { to_table: :season_memberships }
      t.references :finalist_membership, null: false, foreign_key: { to_table: :season_memberships }

      t.timestamps
    end

    add_index :jury_votes, [ :season_id, :juror_membership_id ], unique: true, name: "index_jury_votes_on_season_and_juror"
  end
end
