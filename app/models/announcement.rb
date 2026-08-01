class Announcement < ApplicationRecord
  LIFECYCLE_TYPES = %w[challenge_open challenge_close vote_open vote_close].freeze
  FREEFORM_TYPES = %w[reminder update general].freeze
  TYPES = LIFECYCLE_TYPES + FREEFORM_TYPES

  belongs_to :season
  belongs_to :created_by, class_name: "User"
  belongs_to :round, optional: true

  validates :announcement_type, inclusion: { in: TYPES }
  validates :body, presence: true
  validates :round, presence: { message: "is required for round-lifecycle announcement types" }, if: -> { announcement_type.in?(LIFECYCLE_TYPES) }

  scope :sent, -> { where.not(sent_at: nil) }
  scope :due, -> { where(sent_at: nil).where.not(scheduled_at: nil).where(scheduled_at: ..Time.current) }

  def send_now!
    update!(sent_at: Time.current)
  end
end
