class JuryVote < ApplicationRecord
  belongs_to :season
  belongs_to :juror_membership, class_name: "SeasonMembership"
  belongs_to :finalist_membership, class_name: "SeasonMembership"

  validates :juror_membership_id, uniqueness: { scope: :season_id }
end
