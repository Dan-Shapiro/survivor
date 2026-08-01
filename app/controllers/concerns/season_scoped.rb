module SeasonScoped
  extend ActiveSupport::Concern

  private

  def set_season
    @season = Season.find(params[:season_id] || params[:id])
  end

  def require_host
    return if @season.host_id == current_user.id

    redirect_to season_path(@season), alert: "Only the host can do that."
  end

  # Being logged in isn't enough — every season-scoped page must also check
  # the viewer actually belongs to *this* season, or any account holder
  # could browse any season's roster, results, and messages by guessing IDs.
  def require_season_member
    return if @season.season_memberships.exists?(user: current_user)

    redirect_to root_path, alert: "You're not part of that season."
  end
end
