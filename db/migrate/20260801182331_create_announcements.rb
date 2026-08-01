class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :season, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :round, null: true, foreign_key: true
      t.string :announcement_type, null: false
      t.text :body, null: false
      t.datetime :scheduled_at
      t.datetime :sent_at

      t.timestamps
    end
  end
end
