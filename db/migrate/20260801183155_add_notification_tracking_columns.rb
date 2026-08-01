class AddNotificationTrackingColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :rounds, :challenge_reminder_sent_at, :datetime
    add_column :rounds, :vote_reminder_sent_at, :datetime
    add_column :season_memberships, :last_message_digest_sent_at, :datetime
  end
end
