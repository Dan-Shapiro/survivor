class Challenge < ApplicationRecord
  # "in_app" is deferred (see docs/GAME_DESIGN.md#challenges) — no in-app
  # mini-games are built yet, so it's not offered as a choice, but the value
  # is reserved so existing data doesn't need to change when it lands.
  RESULT_MODES = %w[in_app scores winner_only].freeze
  AVAILABLE_RESULT_MODES = RESULT_MODES - %w[in_app]

  belongs_to :round

  has_many :challenge_results, dependent: :destroy

  validates :title, presence: true
  validates :result_mode, inclusion: { in: RESULT_MODES }
end
