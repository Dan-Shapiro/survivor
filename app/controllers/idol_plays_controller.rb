class IdolPlaysController < ApplicationController
  include SeasonScoped

  before_action :set_season
  before_action :set_round

  def create
    membership = @season.season_memberships.find_by(user: current_user)
    idol = membership&.active_idol
    session = @round.current_voting_session

    unless idol && session
      redirect_to season_round_path(@season, @round), alert: "You don't have an idol to play right now."
      return
    end

    idol.play!(voting_session: session)
    redirect_to season_round_path(@season, @round), notice: "Idol played — votes against you won't count this tribal council."
  rescue RuntimeError => e
    redirect_to season_round_path(@season, @round), alert: e.message
  end

  private

  def set_round
    @round = @season.rounds.find(params[:round_id])
  end
end
