class ChallengeSubmissionsController < ApplicationController
  include SeasonScoped

  before_action :set_season
  before_action :set_round

  def update
    unless @round.status == "challenge_open" && @round.challenge_deadline_at.future?
      redirect_to season_round_path(@season, @round), alert: "Submissions are closed for this challenge."
      return
    end

    membership = @season.season_memberships.find_by(user: current_user)
    result = membership && @round.challenge.challenge_results.find_by(season_membership: membership)

    unless result
      redirect_to season_round_path(@season, @round), alert: "You're not a player in this challenge."
      return
    end

    if result.update(submission_params)
      redirect_to season_round_path(@season, @round), notice: "Submission saved."
    else
      redirect_to season_round_path(@season, @round), alert: result.errors.full_messages.to_sentence
    end
  end

  private

  def set_round
    @round = @season.rounds.find(params[:round_id])
  end

  def submission_params
    params.require(:challenge_result).permit(:proof, :note)
  end
end
