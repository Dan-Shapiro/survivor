class CreateChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :challenges do |t|
      t.references :round, null: false, foreign_key: true, index: { unique: true }
      t.string :title, null: false
      t.text :description
      t.string :result_mode, null: false

      t.timestamps
    end
  end
end
