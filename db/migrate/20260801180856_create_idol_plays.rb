class CreateIdolPlays < ActiveRecord::Migration[8.1]
  def change
    create_table :idol_plays do |t|
      t.references :idol, null: false, foreign_key: true
      t.references :voting_session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
