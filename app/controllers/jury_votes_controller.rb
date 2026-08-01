class JuryVotesController < ApplicationController
  include SeasonScoped

  before_action :set_season

  def create
    juror = @season.season_memberships.find_by(user: current_user)
    finalist = @season.season_memberships.find_by(id: params[:finalist_membership_id])

    unless juror && finalist
      redirect_to season_path(@season), alert: "Pick who you want to win."
      return
    end

    @season.cast_jury_vote!(juror: juror, finalist: finalist)
    redirect_to season_path(@season), notice: "Jury vote cast."
  rescue RuntimeError => e
    redirect_to season_path(@season), alert: e.message
  end
end
