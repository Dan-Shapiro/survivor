class CreateMessageThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :message_threads do |t|
      t.references :season, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :name
      t.references :created_by_membership, null: true, foreign_key: { to_table: :season_memberships }

      t.timestamps
    end
  end
end
