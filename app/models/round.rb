class Round < ApplicationRecord
  PHASES = %w[pre_merge post_merge].freeze
  STATUSES = %w[scheduled challenge_open challenge_closed voting_open voting_closed tribal_completed].freeze

  belongs_to :season
  has_one :challenge, dependent: :destroy
  has_many :voting_sessions, dependent: :destroy

  accepts_nested_attributes_for :challenge

  validates :number, presence: true, uniqueness: { scope: :season_id }
  validates :phase, inclusion: { in: PHASES }
  validates :status, inclusion: { in: STATUSES }

  before_validation :assign_number, on: :create
  before_validation :assign_phase, on: :create

  REMINDER_WINDOW = 1.hour

  scope :challenge_past_due, -> { where(status: "challenge_open").where(challenge_deadline_at: ..Time.current) }
  scope :voting_past_due, -> { where(status: "voting_open").where.not(vote_deadline_at: nil).where(vote_deadline_at: ..Time.current) }

  scope :challenge_reminder_due, -> {
    where(status: "challenge_open", challenge_reminder_sent_at: nil)
      .where.not(challenge_deadline_at: nil)
      .where(challenge_deadline_at: Time.current..REMINDER_WINDOW.from_now)
  }
  scope :vote_reminder_due, -> {
    where(status: "voting_open", vote_reminder_sent_at: nil)
      .where.not(vote_deadline_at: nil)
      .where(vote_deadline_at: Time.current..REMINDER_WINDOW.from_now)
  }

  def open_challenge!(deadline:)
    raise "round is not scheduled" unless status == "scheduled"
    raise "no challenge configured for this round" unless challenge

    transaction do
      season.active_players.find_each do |membership|
        challenge.challenge_results.find_or_create_by!(season_membership: membership)
      end

      update!(status: "challenge_open", challenge_deadline_at: deadline)
    end
  end

  def close_challenge!(auto: false)
    raise "challenge is not open" unless status == "challenge_open"

    update!(status: "challenge_closed", auto_closed: auto)
  end

  # `winner` is a Tribe pre-merge, a SeasonMembership post-merge (individual
  # immunity). It's required for "winner_only" challenges (the host's
  # explicit call, since there's nothing to compute from) and optional for
  # "scores" challenges, where it's only used to break a tie with an equal
  # average/score — otherwise the winner is computed, not picked. Higher
  # score wins; there's no notion of a lower-is-better challenge to account
  # for since the catalog itself is still open-ended (see
  # docs/GAME_DESIGN.md#challenges).
  def finalize_results!(winner: nil, scores: {})
    raise "challenge is not closed" unless status == "challenge_closed"

    # Scores are saved in their own transaction, separate from winner
    # determination below — a tied-score exception must not roll back
    # scores that were just entered, or breaking the tie would require the
    # host to re-enter every player's score from scratch.
    transaction do
      scores.each do |membership_id, score|
        next if score.blank?

        challenge.challenge_results.find_by!(season_membership_id: membership_id).update!(score: score)
      end
    end

    winner = phase == "pre_merge" ? determine_winning_tribe(explicit: winner) : determine_winning_member(explicit: winner)
    grant_immunity_to!(winner)

    winner
  end

  def current_voting_session
    voting_sessions.order(:session_number).last
  end

  # Pre-merge: only the losing tribe(s) — anyone not on a tribe that won
  # immunity this round — vote, choosing among themselves (see
  # docs/GAME_DESIGN.md#core-round-loop). Post-merge (Phase 6) everyone
  # votes, including the immune player, whose incoming votes just don't
  # count — that exclusion happens in the tally, not here, since it applies
  # equally whether "immune" means a whole tribe or one player.
  def open_voting!(deadline: nil)
    raise "challenge is not closed" unless status == "challenge_closed"
    raise "results have not been finalized yet" unless challenge.challenge_results.exists?(is_immune: true)

    voters = eligible_voter_membership_ids

    transaction do
      voting_sessions.create!(session_number: 1, eligible_voter_ids: voters, candidate_ids: voters,
        status: "open", opened_at: Time.current)
      update!(status: "voting_open", vote_deadline_at: deadline)
    end
  end

  def close_voting!(auto: false)
    raise "voting is not open" unless status == "voting_open"

    transaction do
      current_voting_session.update!(status: "closed", closed_at: Time.current)
      update!(status: "voting_closed", auto_closed: auto)
    end
  end

  # Either finalizes an elimination, or — on a tie — reveals the tie and
  # automatically opens a revote among just the tied players (everyone else
  # sits it out; see docs/GAME_DESIGN.md#voting--tribal-council).
  def reveal_tribal_council!
    raise "voting is not closed" unless status == "voting_closed"

    session = current_voting_session
    # Votes cast for the immune player still exist (they're a valid target,
    # per docs/GAME_DESIGN.md#core-round-loop) but never count toward
    # elimination. Pre-merge, the immune tribe isn't in candidate_ids at
    # all, so this is a no-op there; post-merge it excludes just the one
    # immune individual. Idol-protected players are excluded the same way.
    immune_ids = challenge.challenge_results.where(is_immune: true).pluck(:season_membership_id)
    idol_protected_ids = session.idol_plays.joins(:idol).pluck("idols.holder_membership_id")
    excluded_ids = immune_ids + idol_protected_ids
    tally = session.tally.each_with_object({}) { |(id, count), h| h[id] = excluded_ids.include?(id) ? 0 : count }
    top_count = tally.values.max.to_i
    raise "no votes were cast" if top_count.zero?

    tied_ids = tally.select { |_, count| count == top_count }.keys

    # Only post-merge eliminations join the jury (classic-show rule) — see
    # docs/GAME_DESIGN.md#scoring--win-condition.
    eliminated_status = phase == "post_merge" ? "jury" : "eliminated"

    transaction do
      if tied_ids.one?
        eliminated_id = tied_ids.first
        result = session.create_tribal_council_result!(tally: tally, eliminated_membership_id: eliminated_id, revealed_at: Time.current)
        SeasonMembership.find(eliminated_id).update!(status: eliminated_status, role: "spectator")
        update!(status: "tribal_completed")
        result
      else
        result = session.create_tribal_council_result!(tally: tally, eliminated_membership_id: nil, revealed_at: Time.current)
        voters = session.eligible_voter_ids - tied_ids
        voting_sessions.create!(session_number: session.session_number + 1, eligible_voter_ids: voters,
          candidate_ids: tied_ids, status: "open", opened_at: Time.current)
        update!(status: "voting_open", vote_deadline_at: nil)
        result
      end
    end
  end

  private

  def eligible_voter_membership_ids
    if phase == "pre_merge"
      immune_tribe_ids = challenge.challenge_results.where(is_immune: true)
        .joins(:season_membership).pluck("season_memberships.tribe_id").compact.uniq
      season.active_players.where.not(tribe_id: immune_tribe_ids).pluck(:id)
    else
      season.active_players.pluck(:id)
    end
  end

  def determine_winning_tribe(explicit:)
    if explicit
      raise "winning tribe must belong to this season" unless explicit.season_id == season_id
    end

    if challenge.result_mode == "winner_only"
      raise "a winning tribe is required for winner-only challenges" unless explicit
      return explicit
    end

    raise "every active player needs a score before results can be finalized" unless all_active_players_scored?

    tribe_averages = season.tribes.filter_map do |tribe|
      scores = challenge.challenge_results.joins(:season_membership)
        .where(season_memberships: { tribe_id: tribe.id })
        .pluck(:score)
      [ tribe, scores.sum.to_f / scores.size ] if scores.any?
    end.to_h

    top_average = tribe_averages.values.max
    top_tribes = tribe_averages.select { |_, avg| avg == top_average }.keys
    return top_tribes.first if top_tribes.one?

    unless explicit && top_tribes.include?(explicit)
      raise "tied average score between #{top_tribes.map(&:name).join(', ')} — pick a tribe to break the tie"
    end

    explicit
  end

  def determine_winning_member(explicit:)
    if explicit
      raise "winner must be an active player in this season" unless season.active_players.exists?(id: explicit.id)
    end

    if challenge.result_mode == "winner_only"
      raise "a winner is required for winner-only challenges" unless explicit
      return explicit
    end

    raise "every active player needs a score before results can be finalized" unless all_active_players_scored?

    scores_by_membership = challenge.challenge_results.where.not(score: nil).pluck(:season_membership_id, :score).to_h
    top_score = scores_by_membership.values.max
    top_membership_ids = scores_by_membership.select { |_, score| score == top_score }.keys
    return SeasonMembership.find(top_membership_ids.first) if top_membership_ids.one?

    unless explicit && top_membership_ids.include?(explicit.id)
      names = SeasonMembership.where(id: top_membership_ids).map { |m| m.user.display_name }.join(", ")
      raise "tied score between #{names} — pick a player to break the tie"
    end

    explicit
  end

  def grant_immunity_to!(winner)
    winner_membership_ids = winner.is_a?(Tribe) ? season.season_memberships.where(tribe_id: winner.id).pluck(:id) : [ winner.id ]
    challenge.challenge_results.where(season_membership_id: winner_membership_ids).update_all(is_immune: true)
  end

  def all_active_players_scored?
    season.active_players.pluck(:id).all? do |membership_id|
      challenge.challenge_results.find_by(season_membership_id: membership_id)&.score.present?
    end
  end

  def assign_number
    self.number ||= season.rounds.maximum(:number).to_i + 1
  end

  def assign_phase
    self.phase ||= (season.status == "merged" ? "post_merge" : "pre_merge")
  end
end
