class TribalCouncilResult < ApplicationRecord
  belongs_to :voting_session
  belongs_to :eliminated_membership, class_name: "SeasonMembership", optional: true
end
