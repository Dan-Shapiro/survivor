class Message < ApplicationRecord
  belongs_to :message_thread
  belongs_to :sender_membership, class_name: "SeasonMembership"

  validates :body, presence: true
end
