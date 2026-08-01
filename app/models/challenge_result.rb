class ChallengeResult < ApplicationRecord
  belongs_to :challenge
  belongs_to :season_membership

  has_one_attached :proof

  validates :season_membership_id, uniqueness: { scope: :challenge_id }
end
