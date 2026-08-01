class CreateSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :seasons do |t|
      t.string :name, null: false
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "setup"
      t.string :invite_code, null: false
      t.integer :jury_size, null: false, default: 9

      t.timestamps
    end
    add_index :seasons, :invite_code, unique: true
  end
end
