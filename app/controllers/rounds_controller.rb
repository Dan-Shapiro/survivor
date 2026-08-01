class RoundsController < ApplicationController
  include SeasonScoped
  include EmailNotifications

  ROUND_ACTIONS = %i[show open_challenge close_challenge finalize_results open_voting close_voting reveal_tribal_council].freeze
  HOST_ACTIONS = ROUND_ACTIONS - %i[show] + %i[new create]

  before_action :set_season
  before_action :require_season_member
  before_action :set_round, only: ROUND_ACTIONS
  before_action :require_host, only: HOST_ACTIONS

  def new
    @round = @season.rounds.build
    @round.build_challenge
  end

  def create
    @round = @season.rounds.build(round_params)

    if @round.save
      redirect_to season_round_path(@season, @round), notice: "Round #{@round.number} configured."
    else
      @round.build_challenge unless @round.challenge
      render :new, status: :unprocessable_entity
    end
  end

  def show
    is_host = @season.host_id == current_user.id

    @challenge_results = @round.challenge&.challenge_results&.includes(season_membership: :user)
    @tribes = @season.tribes.order(:name)
    @my_result = @challenge_results&.find { |result| result.season_membership.user_id == current_user.id }

    @voting_sessions = @round.voting_sessions.includes(:tribal_council_result, votes: %i[voter_membership voted_for_membership]).order(:session_number)
    @voting_session = @voting_sessions.last
    @my_membership = @season.season_memberships.find_by(user: current_user)
    @is_host = is_host
    @membership_names = @season.season_memberships.includes(:user).to_h { |m| [ m.id, m.user.display_name ] }
  end

  def open_challenge
    @round.open_challenge!(deadline: parse_deadline)
    @season.active_players.each do |membership|
      notify_safely { SeasonMailer.challenge_opened(round: @round, membership: membership).deliver_now }
    end
    redirect_to season_round_path(@season, @round), notice: "Challenge is open."
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  def close_challenge
    @round.close_challenge!
    redirect_to season_round_path(@season, @round), notice: "Challenge closed."
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  def finalize_results
    winner = @round.finalize_results!(winner: explicit_winner, scores: params[:scores] || {})
    winner_name = winner.is_a?(Tribe) ? winner.name : winner.user.display_name
    redirect_to season_round_path(@season, @round), notice: "#{winner_name} is immune."
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  def open_voting
    @round.open_voting!(deadline: params[:vote_deadline_at].presence && Time.zone.parse(params[:vote_deadline_at]))
    redirect_to season_round_path(@season, @round), notice: "Voting is open."
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  def close_voting
    @round.close_voting!
    redirect_to season_round_path(@season, @round), notice: "Voting closed."
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  def reveal_tribal_council
    result = @round.reveal_tribal_council!
    # Results are public (see docs/GAME_DESIGN.md#voting--tribal-council) —
    # every season member gets notified, not just active players.
    @season.season_memberships.each do |membership|
      notify_safely { SeasonMailer.tribal_council_revealed(result: result, membership: membership).deliver_now }
    end
    notice = result.eliminated_membership ? "#{result.eliminated_membership.user.display_name} was voted out." : "It's a tie — revote opened among the tied players."
    redirect_to season_round_path(@season, @round), notice: notice
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  private

  def set_round
    @round = @season.rounds.find(params[:id])
  end

  def round_params
    params.require(:round).permit(challenge_attributes: %i[title description result_mode])
  end

  def parse_deadline
    Time.zone.parse(params[:challenge_deadline_at])
  end

  def explicit_winner
    return nil if params[:winner_id].blank?

    @round.phase == "pre_merge" ? @season.tribes.find(params[:winner_id]) : @season.season_memberships.find(params[:winner_id])
  end
end
