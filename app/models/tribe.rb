class Tribe < ApplicationRecord
  belongs_to :season

  has_many :season_memberships, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :season_id }
end
