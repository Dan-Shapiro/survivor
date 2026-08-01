class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :pin_digest, null: false
      t.string :display_name, null: false

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
