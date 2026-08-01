class SeasonMembership < ApplicationRecord
  ROLES = %w[host player spectator].freeze
  STATUSES = %w[active eliminated jury removed].freeze

  belongs_to :season
  belongs_to :user
  belongs_to :tribe, optional: true

  has_many :challenge_results, dependent: :destroy
  has_many :idols, foreign_key: :holder_membership_id, inverse_of: :holder_membership, dependent: :destroy
  has_many :thread_participants, dependent: :destroy
  has_many :message_threads, through: :thread_participants

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :season_id }
  validate :tribe_belongs_to_same_season

  def active_idol
    idols.find_by(status: "active")
  end

  # For chronic inactivity or quitting mid-season (see
  # docs/GAME_DESIGN.md#edge-cases) — distinct from "eliminated"/"jury",
  # which only ever happen through an actual tribal council vote.
  def remove!
    raise "only active players can be removed" unless role == "player" && status == "active"

    update!(status: "removed", role: "spectator")
  end

  private

  def tribe_belongs_to_same_season
    return if tribe.nil? || tribe.season_id == season_id

    errors.add(:tribe, "must belong to the same season")
  end
end
