class CreateChallengeResults < ActiveRecord::Migration[8.1]
  def change
    create_table :challenge_results do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :season_membership, null: false, foreign_key: true
      t.integer :score
      t.boolean :is_immune, null: false, default: false
      t.text :note

      t.timestamps
    end

    add_index :challenge_results, [ :challenge_id, :season_membership_id ], unique: true, name: "index_challenge_results_on_challenge_and_membership"
  end
end
