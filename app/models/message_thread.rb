class MessageThread < ApplicationRecord
  KINDS = %w[public dm group].freeze

  belongs_to :season
  belongs_to :created_by_membership, class_name: "SeasonMembership", optional: true

  has_many :thread_participants, dependent: :destroy
  has_many :season_memberships, through: :thread_participants
  has_many :messages, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }

  # Spectators (read-only per docs/GAME_DESIGN.md#players--roles) can see
  # the public thread but never private DMs/alliance chats — including ones
  # they were a participant in before they were eliminated, since a
  # spectator's visibility is deliberately reset to "read-only public only."
  def visible_to?(membership)
    return true if kind == "public"

    membership.role != "spectator" && season_memberships.exists?(id: membership.id)
  end

  def postable_by?(membership)
    return false if membership.role == "spectator"

    kind == "public" || season_memberships.exists?(id: membership.id)
  end

  def post!(sender:, body:)
    raise "you can't post in this thread" unless postable_by?(sender)

    messages.create!(sender_membership: sender, body: body)
  end

  # `since` lets a caller (the digest mailer job) count only messages newer
  # than the later of "last read" or "last digested" — without it, a
  # digest would re-include the same unread messages on every scheduler
  # tick forever for a player who never opens the app.
  def unread_count_for(membership, since: nil)
    participant = thread_participants.find_by(season_membership: membership)
    floor = [ participant&.last_read_at, since ].compact.max

    scope = messages.where.not(sender_membership_id: membership.id)
    scope = scope.where(created_at: (floor + 0.seconds)..) if floor
    scope.count
  end

  def mark_read!(membership)
    participant = thread_participants.find_or_initialize_by(season_membership: membership)
    participant.last_read_at = Time.current
    participant.save!
  end
end
