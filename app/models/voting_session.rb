class VotingSession < ApplicationRecord
  STATUSES = %w[open closed].freeze

  belongs_to :round

  has_many :votes, dependent: :destroy
  has_one :tribal_council_result, dependent: :destroy
  has_many :idol_plays, dependent: :destroy

  validates :session_number, presence: true, uniqueness: { scope: :round_id }
  validates :status, inclusion: { in: STATUSES }

  def cast_vote!(voter:, target:)
    raise "voting is not open" unless status == "open"
    raise "not eligible to vote in this session" unless eligible_voter_ids.include?(voter.id)
    raise "not a valid candidate" unless candidate_ids.include?(target.id)
    raise "you can't vote for yourself" if voter.id == target.id

    vote = votes.find_or_initialize_by(voter_membership: voter)
    vote.voted_for_membership = target
    vote.save!
    vote
  end

  # Zero-filled so a candidate with no votes still appears in the tally,
  # keyed by season_membership id.
  def tally
    counts = candidate_ids.index_with { 0 }

    votes.each do |vote|
      target_id = vote.voted_for_membership_id
      counts[target_id] += 1 if counts.key?(target_id)
    end

    counts
  end
end
