class InvitesController < ApplicationController
  allow_unauthenticated_access only: %i[show]

  before_action :set_season

  def show
    @already_member = logged_in? && @season.season_memberships.exists?(user: current_user)
  end

  def create
    if @season.status != "setup"
      redirect_to join_path(@season.invite_code), alert: "This season has already started."
      return
    end

    membership = @season.season_memberships.find_or_initialize_by(user: current_user)
    membership.role ||= "player"
    membership.status ||= "active"

    if membership.new_record? ? membership.save : true
      redirect_to season_path(@season), notice: "You're in — welcome to #{@season.name}."
    else
      redirect_to join_path(@season.invite_code), alert: membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_season
    @season = Season.find_by!(invite_code: params[:invite_code])
  end
end
