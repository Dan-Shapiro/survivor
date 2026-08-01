class Season < ApplicationRecord
  MINIMUM_PLAYERS = 12
  DEFAULT_JURY_SIZE = 9

  STATUSES = %w[setup active merged jury complete].freeze

  belongs_to :host, class_name: "User", inverse_of: :hosted_seasons

  has_many :tribes, dependent: :destroy
  has_many :season_memberships, dependent: :destroy
  has_many :users, through: :season_memberships
  has_many :rounds, dependent: :destroy
  has_many :jury_votes, dependent: :destroy
  has_many :idols, dependent: :destroy
  has_many :message_threads, dependent: :destroy
  has_many :announcements, dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :invite_code, presence: true, uniqueness: true
  validates :jury_size, numericality: { only_integer: true, greater_than: 0 }

  before_validation :generate_invite_code, on: :create
  after_create :create_host_membership

  def players
    season_memberships.where(role: "player")
  end

  def active_players
    players.where(status: "active")
  end

  # Only post-merge eliminations join the jury (classic-show rule) — see
  # docs/GAME_DESIGN.md#scoring--win-condition.
  def jurors
    season_memberships.where(status: "jury")
  end

  # A season can only start once there are enough active players to
  # guarantee the worst case of 3 finalists + a full jury (see
  # docs/GAME_DESIGN.md#scoring--win-condition).
  def startable?
    status == "setup" && active_players.count >= MINIMUM_PLAYERS
  end

  # Host discretion only for v1 — no in-app hunt yet (see
  # docs/GAME_DESIGN.md#voting--tribal-council).
  def grant_idol!(to:, granted_by:)
    raise "season is not active" unless status.in?(%w[active merged])
    raise "player must be an active player in this season" unless active_players.exists?(id: to.id)

    idols.create!(holder_membership: to, granted_by: granted_by, granted_at: Time.current)
  end

  # Collapses tribes into individual play. Timing is the host's judgment
  # call (classic Survivor has no fixed merge point) — rounds created after
  # this pick up "post_merge" phase automatically (see Round#assign_phase).
  def merge!
    raise "season is not active" unless status == "active"

    update!(status: "merged")
  end

  # Once down to the finalists the host wants, close out challenges/voting
  # and open the jury vote.
  def start_jury_phase!
    raise "season is not merged" unless status == "merged"
    raise "need at least 2 finalists" unless active_players.count >= 2

    update!(status: "jury")
  end

  def cast_jury_vote!(juror:, finalist:)
    raise "jury voting is not open" unless status == "jury"
    raise "not a member of the jury" unless jurors.exists?(id: juror.id)
    raise "not a finalist" unless active_players.exists?(id: finalist.id)

    vote = jury_votes.find_or_initialize_by(juror_membership: juror)
    vote.finalist_membership = finalist
    vote.save!
    vote
  end

  def jury_tally
    tally = active_players.pluck(:id).index_with { 0 }

    jury_votes.each do |vote|
      tally[vote.finalist_membership_id] += 1 if tally.key?(vote.finalist_membership_id)
    end

    tally
  end

  # winner is only needed to break a tie for first place; otherwise the
  # winner is whoever the jury actually voted for, not a host pick.
  def reveal_finale!(winner: nil)
    raise "jury voting is not open" unless status == "jury"

    tally = jury_tally
    top_votes = tally.values.max.to_i
    raise "no jury votes were cast" if top_votes.zero?

    tied_ids = tally.select { |_, count| count == top_votes }.keys

    winner_id =
      if tied_ids.one?
        tied_ids.first
      elsif winner && tied_ids.include?(winner.id)
        winner.id
      else
        names = SeasonMembership.where(id: tied_ids).map { |m| m.user.display_name }.join(", ")
        raise "tied jury vote between #{names} — pick a winner to break the tie"
      end

    transaction do
      ranked = tally.sort_by { |_, count| -count }.map(&:first)
      ranked = [ winner_id ] + (ranked - [ winner_id ]) # winner always placement 1, even if not first in raw sort due to a tie-break
      ranked.each_with_index { |membership_id, index| SeasonMembership.find(membership_id).update!(placement: index + 1) }
      update!(status: "complete")
    end

    SeasonMembership.find(winner_id)
  end

  def public_thread
    message_threads.find_or_create_by!(kind: "public")
  end

  # Reuses an existing DM between the two if one already exists, rather than
  # spawning duplicate threads every time someone starts a new conversation.
  def find_or_create_dm!(between:)
    a, b = between
    raise "can't DM yourself" if a.id == b.id
    raise "spectators can't start DMs" if a.role == "spectator" || b.role == "spectator"

    existing = message_threads.where(kind: "dm")
      .joins(:thread_participants)
      .where(thread_participants: { season_membership_id: [ a.id, b.id ] })
      .group("message_threads.id")
      .having("COUNT(DISTINCT thread_participants.season_membership_id) = 2")
      .having("COUNT(thread_participants.id) = 2")
      .first
    return existing if existing

    transaction do
      thread = message_threads.create!(kind: "dm", created_by_membership: a)
      thread.thread_participants.create!(season_membership: a)
      thread.thread_participants.create!(season_membership: b)
      thread
    end
  end

  def create_group!(name:, creator:, participants:)
    raise "spectators can't start groups" if creator.role == "spectator"

    members = (participants + [ creator ]).uniq(&:id)

    transaction do
      thread = message_threads.create!(kind: "group", name: name, created_by_membership: creator)
      members.each { |m| thread.thread_participants.create!(season_membership: m) }
      thread
    end
  end

  # One-time only, no recurring (see docs/GAME_DESIGN.md#host-announcements).
  # A future scheduled_at defers sending to the scheduler endpoint's
  # Announcement.due job; otherwise it sends immediately.
  def announce!(created_by:, announcement_type:, body:, round: nil, scheduled_at: nil)
    immediate = scheduled_at.blank? || scheduled_at <= Time.current

    announcements.create!(created_by: created_by, announcement_type: announcement_type, body: body,
      round: round, scheduled_at: scheduled_at, sent_at: (Time.current if immediate))
  end

  private

  def generate_invite_code
    self.invite_code ||= SecureRandom.urlsafe_base64(8)
  end

  def create_host_membership
    season_memberships.create!(user: host, role: "host", status: "active")
  end
end
