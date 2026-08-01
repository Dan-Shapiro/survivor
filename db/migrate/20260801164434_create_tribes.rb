class CreateTribes < ActiveRecord::Migration[8.1]
  def change
    create_table :tribes do |t|
      t.references :season, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
