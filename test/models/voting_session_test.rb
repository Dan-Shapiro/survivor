require "test_helper"

class VotingSessionTest < ActiveSupport::TestCase
  setup do
    @data = build_active_season
    @round = open_round_with_immunity(season: @data[:season], immune_tribe: @data[:tribe_a])
    @round.open_voting!
    @session = @round.current_voting_session
    @losing = @data[:memberships].select { |m| m.tribe == @data[:tribe_b] }
  end

  test "a player cannot vote for themselves" do
    voter = @losing.first

    error = assert_raises(RuntimeError) { @session.cast_vote!(voter: voter, target: voter) }
    assert_match(/vote for yourself/, error.message)
  end

  test "the model-level guard blocks a self-vote even if cast_vote! is bypassed" do
    voter = @losing.first
    vote = Vote.new(voting_session: @session, voter_membership: voter, voted_for_membership: voter)

    refute vote.valid?
    assert_includes vote.errors[:voted_for_membership_id], "can't be yourself"
  end

  test "a member of the winning (immune) tribe cannot vote in this session" do
    winning_member = @data[:memberships].find { |m| m.tribe == @data[:tribe_a] }
    target = @losing.first

    error = assert_raises(RuntimeError) { @session.cast_vote!(voter: winning_member, target: target) }
    assert_match(/not eligible/, error.message)
  end

  test "casting a second vote changes the first rather than creating a duplicate" do
    voter = @losing[0]
    first_target = @losing[1]
    second_target = @losing[2]

    @session.cast_vote!(voter: voter, target: first_target)
    @session.cast_vote!(voter: voter, target: second_target)

    assert_equal 1, @session.votes.where(voter_membership: voter).count
    assert_equal second_target.id, @session.votes.find_by(voter_membership: voter).voted_for_membership_id
  end

  test "tally is zero-filled for candidates with no votes" do
    @session.cast_vote!(voter: @losing[0], target: @losing[1])

    tally = @session.tally
    assert_equal 1, tally[@losing[1].id]
    assert_equal 0, tally[@losing[2].id]
  end
end
