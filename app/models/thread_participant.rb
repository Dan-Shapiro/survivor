class ThreadParticipant < ApplicationRecord
  belongs_to :message_thread
  belongs_to :season_membership

  validates :season_membership_id, uniqueness: { scope: :message_thread_id }
end
