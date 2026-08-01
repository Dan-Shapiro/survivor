class CreateIdols < ActiveRecord::Migration[8.1]
  def change
    create_table :idols do |t|
      t.references :season, null: false, foreign_key: true
      t.references :holder_membership, null: false, foreign_key: { to_table: :season_memberships }
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "active"
      t.datetime :granted_at, null: false
      t.datetime :used_at

      t.timestamps
    end
  end
end
