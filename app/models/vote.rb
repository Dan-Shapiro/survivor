class Vote < ApplicationRecord
  belongs_to :voting_session
  belongs_to :voter_membership, class_name: "SeasonMembership"
  belongs_to :voted_for_membership, class_name: "SeasonMembership"

  validates :voter_membership_id, uniqueness: { scope: :voting_session_id }
  validate :cannot_vote_for_self

  private

  def cannot_vote_for_self
    return if voter_membership_id.blank? || voted_for_membership_id.blank?
    return if voter_membership_id != voted_for_membership_id

    errors.add(:voted_for_membership_id, "can't be yourself")
  end
end
