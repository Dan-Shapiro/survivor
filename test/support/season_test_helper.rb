module SeasonTestHelper
  # Builds a 12-player, 2-tribe active season — the minimum shape needed to
  # exercise the challenge -> vote -> tribal council loop pre-merge.
  def build_active_season(player_count: 12)
    host = User.create!(email: "host@example.com", display_name: "Host", pin: "1234", pin_confirmation: "1234")
    season = Season.create!(name: "Test Season", host: host)
    tribe_a = season.tribes.create!(name: "Kalo")
    tribe_b = season.tribes.create!(name: "Manu")

    memberships = player_count.times.map do |i|
      user = User.create!(email: "player#{i}@example.com", display_name: "Player #{i}", pin: "1111", pin_confirmation: "1111")
      tribe = i.even? ? tribe_a : tribe_b
      season.season_memberships.create!(user: user, role: "player", status: "active", tribe: tribe)
    end

    season.update!(status: "active")

    { season: season, host: host, tribe_a: tribe_a, tribe_b: tribe_b, memberships: memberships }
  end

  # Advances a fresh round through to "challenge_closed" with the given
  # tribe immune, ready for open_voting!.
  def open_round_with_immunity(season:, immune_tribe:, result_mode: "winner_only")
    round = season.rounds.create!(challenge_attributes: { title: "Challenge", description: "t", result_mode: result_mode })
    round.open_challenge!(deadline: 1.hour.from_now)
    round.close_challenge!
    round.finalize_results!(winner: immune_tribe)
    round
  end
end
