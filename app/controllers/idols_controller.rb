class IdolsController < ApplicationController
  include SeasonScoped
  include EmailNotifications

  before_action :set_season
  before_action :require_host

  def create
    holder = @season.season_memberships.find_by(id: params[:holder_membership_id])

    unless holder
      redirect_to season_path(@season), alert: "Pick who should get the idol."
      return
    end

    idol = @season.grant_idol!(to: holder, granted_by: current_user)
    notify_safely { SeasonMailer.idol_granted(idol: idol).deliver_now }

    redirect_to season_path(@season), notice: "Idol granted to #{holder.user.display_name}."
  rescue RuntimeError => e
    redirect_to season_path(@season), alert: e.message
  end
end
