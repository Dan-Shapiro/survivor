class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.references :season, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :phase, null: false
      t.string :status, null: false, default: "scheduled"
      t.datetime :challenge_deadline_at
      t.datetime :vote_deadline_at
      t.boolean :auto_closed, null: false, default: false

      t.timestamps
    end

    add_index :rounds, [ :season_id, :number ], unique: true
  end
end
