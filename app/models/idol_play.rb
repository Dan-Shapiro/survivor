class IdolPlay < ApplicationRecord
  belongs_to :idol
  belongs_to :voting_session
end
