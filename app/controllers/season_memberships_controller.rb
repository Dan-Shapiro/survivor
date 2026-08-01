class SeasonMembershipsController < ApplicationController
  include SeasonScoped

  before_action :set_season
  before_action :require_host

  def update
    membership = @season.season_memberships.find(params[:id])

    if membership.update(membership_params)
      redirect_to season_path(@season), notice: "#{membership.user.display_name} assigned to #{membership.tribe&.name || "no tribe"}."
    else
      redirect_to season_path(@season), alert: membership.errors.full_messages.to_sentence
    end
  end

  def remove
    membership = @season.season_memberships.find(params[:id])
    membership.remove!
    redirect_to season_path(@season), notice: "#{membership.user.display_name} was removed from the season."
  rescue RuntimeError => e
    redirect_to season_path(@season), alert: e.message
  end

  def reset_pin
    membership = @season.season_memberships.find(params[:id])
    new_pin = membership.user.reset_pin!
    redirect_to season_path(@season), notice: "#{membership.user.display_name}'s new PIN is #{new_pin} — relay it to them directly."
  end

  private

  def membership_params
    params.require(:season_membership).permit(:tribe_id)
  end
end
