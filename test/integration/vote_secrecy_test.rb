require "test_helper"

class VoteSecrecyTest < ActionDispatch::IntegrationTest
  setup do
    @data = build_active_season
    @round = open_round_with_immunity(season: @data[:season], immune_tribe: @data[:tribe_a])
    @round.open_voting!
    session = @round.current_voting_session
    losing = @data[:memberships].select { |m| m.tribe == @data[:tribe_b] }
    session.cast_vote!(voter: losing[0], target: losing[1])
    @voter = losing[0]
    @target = losing[1]
  end

  test "a non-host player never sees who voted for whom" do
    login_as(@voter.user, pin: "1111")

    get season_round_path(@data[:season], @round)

    assert_response :success
    refute_match(/Voted for/, response.body)
    refute_includes response.body, "#{@voter.user.display_name}</td>\n              <td>#{@target.user.display_name}"
  end

  test "the host can see the individual ballot" do
    login_as(@data[:host], pin: "1234")

    get season_round_path(@data[:season], @round)

    assert_response :success
    assert_match(/Voted for/, response.body)
    assert_match(/#{@voter.user.display_name}/, response.body)
    assert_match(/#{@target.user.display_name}/, response.body)
  end

  test "an outsider with no membership in the season is redirected, not shown the page" do
    outsider = User.create!(email: "outsider@example.com", display_name: "Outsider", pin: "9999", pin_confirmation: "9999")
    login_as(outsider, pin: "9999")

    get season_round_path(@data[:season], @round)

    assert_redirected_to root_path
  end

  private

  def login_as(user, pin:)
    post login_path, params: { email: user.email, pin: pin }
  end
end
