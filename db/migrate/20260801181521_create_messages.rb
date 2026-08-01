class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.references :sender_membership, null: false, foreign_key: { to_table: :season_memberships }
      t.text :body, null: false

      t.timestamps
    end
  end
end
