class CreateSeasonMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :season_memberships do |t|
      t.references :season, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :tribe, null: true, foreign_key: true
      t.string :role, null: false
      t.string :status, null: false, default: "active"
      t.integer :placement

      t.timestamps
    end

    add_index :season_memberships, [ :season_id, :user_id ], unique: true
  end
end
