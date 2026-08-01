class VotesController < ApplicationController
  include SeasonScoped

  before_action :set_season
  before_action :set_round

  def create
    membership = @season.season_memberships.find_by(user: current_user)
    session = @round.current_voting_session

    unless membership && session
      redirect_to season_round_path(@season, @round), alert: "There's no open vote for you right now."
      return
    end

    target = @season.season_memberships.find_by(id: params[:target_membership_id])

    unless target
      redirect_to season_round_path(@season, @round), alert: "Pick who you want to vote for."
      return
    end

    session.cast_vote!(voter: membership, target: target)
    redirect_to season_round_path(@season, @round), notice: "Vote cast."
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  private

  def set_round
    @round = @season.rounds.find(params[:round_id])
  end
end
