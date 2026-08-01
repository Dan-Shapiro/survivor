require "test_helper"

class RoundTest < ActiveSupport::TestCase
  test "losing tribe votes, winning tribe is not eligible" do
    data = build_active_season
    round = open_round_with_immunity(season: data[:season], immune_tribe: data[:tribe_a])
    round.open_voting!

    session = round.current_voting_session
    losing_ids = data[:memberships].select { |m| m.tribe == data[:tribe_b] }.map(&:id)
    winning_ids = data[:memberships].select { |m| m.tribe == data[:tribe_a] }.map(&:id)

    assert_equal losing_ids.sort, session.eligible_voter_ids.sort
    assert_equal losing_ids.sort, session.candidate_ids.sort
    assert_empty session.eligible_voter_ids & winning_ids
  end

  test "a tied vote opens a revote among only the tied players" do
    data = build_active_season
    round = open_round_with_immunity(season: data[:season], immune_tribe: data[:tribe_a])
    round.open_voting!
    session = round.current_voting_session

    losing = data[:memberships].select { |m| m.tribe == data[:tribe_b] }
    target_a, target_b = losing[0], losing[1]
    voters = losing[2..] # 4 remaining voters, split 2-2 to force a tie
    voters.each_with_index { |voter, i| session.cast_vote!(voter: voter, target: i.even? ? target_a : target_b) }

    round.close_voting!
    result = round.reveal_tribal_council!

    assert_nil result.eliminated_membership_id
    assert_equal "voting_open", round.reload.status

    revote = round.current_voting_session
    assert_equal 2, revote.session_number
    assert_equal [ target_a.id, target_b.id ].sort, revote.candidate_ids.sort
    refute revote.eligible_voter_ids.include?(target_a.id)
    refute revote.eligible_voter_ids.include?(target_b.id)
  end

  test "revote resolves the tie and eliminates the player, marking them a spectator" do
    data = build_active_season
    round = open_round_with_immunity(season: data[:season], immune_tribe: data[:tribe_a])
    round.open_voting!
    session = round.current_voting_session

    losing = data[:memberships].select { |m| m.tribe == data[:tribe_b] }
    target_a, target_b = losing[0], losing[1]
    losing[2..].each_with_index { |voter, i| session.cast_vote!(voter: voter, target: i.even? ? target_a : target_b) }
    round.close_voting!
    round.reveal_tribal_council!

    revote = round.current_voting_session
    revote.eligible_voter_ids.each { |voter_id| revote.cast_vote!(voter: SeasonMembership.find(voter_id), target: target_a) }
    round.close_voting!
    result = round.reveal_tribal_council!

    assert_equal target_a.id, result.eliminated_membership_id
    target_a.reload
    assert_equal "eliminated", target_a.status
    assert_equal "spectator", target_a.role
    assert_equal "tribal_completed", round.reload.status
  end

  test "post-merge elimination sets status to jury instead of eliminated" do
    data = build_active_season
    data[:season].merge!
    round = data[:season].rounds.create!(challenge_attributes: { title: "Solo", description: "t", result_mode: "winner_only" })
    assert_equal "post_merge", round.phase

    winner_membership = data[:memberships].first
    round.open_challenge!(deadline: 1.hour.from_now)
    round.close_challenge!
    round.finalize_results!(winner: winner_membership)
    round.open_voting!

    session = round.current_voting_session
    target = data[:memberships][1]
    (data[:memberships] - [ target ]).each { |voter| session.cast_vote!(voter: voter, target: target) }
    round.close_voting!
    result = round.reveal_tribal_council!

    assert_equal target.id, result.eliminated_membership_id
    assert_equal "jury", target.reload.status
  end

  test "votes cast for the immune player never count toward their elimination" do
    data = build_active_season
    data[:season].merge!
    round = data[:season].rounds.create!(challenge_attributes: { title: "Solo", description: "t", result_mode: "winner_only" })
    immune_membership = data[:memberships].first
    round.open_challenge!(deadline: 1.hour.from_now)
    round.close_challenge!
    round.finalize_results!(winner: immune_membership)
    round.open_voting!

    session = round.current_voting_session
    other_target = data[:memberships][1]
    # Everyone except the immune player votes for the immune player (all of
    # which get nullified); the immune player casts the sole vote against
    # other_target, who should end up the only one with a counted vote.
    (data[:memberships] - [ immune_membership, other_target ]).each do |voter|
      session.cast_vote!(voter: voter, target: immune_membership)
    end
    session.cast_vote!(voter: other_target, target: immune_membership)
    session.cast_vote!(voter: immune_membership, target: other_target)
    round.close_voting!
    result = round.reveal_tribal_council!

    assert_equal other_target.id, result.eliminated_membership_id
    # jsonb stringifies hash keys on assignment (see Round#reveal_tribal_council!'s
    # tally, and the same handling in app/views/rounds/show.html.erb).
    assert_equal 0, result.tally[immune_membership.id.to_s]
  end
end
