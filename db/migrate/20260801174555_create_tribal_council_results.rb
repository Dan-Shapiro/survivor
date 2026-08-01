class CreateTribalCouncilResults < ActiveRecord::Migration[8.1]
  def change
    create_table :tribal_council_results do |t|
      t.references :voting_session, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :tally, null: false, default: {}
      t.references :eliminated_membership, null: true, foreign_key: { to_table: :season_memberships }
      t.datetime :revealed_at, null: false

      t.timestamps
    end
  end
end
