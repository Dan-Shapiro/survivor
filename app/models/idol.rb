class Idol < ApplicationRecord
  STATUSES = %w[active used].freeze

  belongs_to :season
  belongs_to :holder_membership, class_name: "SeasonMembership"
  belongs_to :granted_by, class_name: "User"

  has_many :idol_plays, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }

  # Self-protect only for v1 — cancels votes against the holder in the given
  # voting session (see docs/GAME_DESIGN.md#voting--tribal-council). Must be
  # played before the host reveals that tribal council.
  def play!(voting_session:)
    raise "idol has already been used" unless status == "active"
    raise "idol does not belong to this season" unless voting_session.round.season_id == season_id
    raise "voting has already been revealed" if voting_session.tribal_council_result.present?

    transaction do
      idol_plays.create!(voting_session: voting_session)
      update!(status: "used", used_at: Time.current)
    end
  end
end
