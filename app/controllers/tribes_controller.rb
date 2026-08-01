class TribesController < ApplicationController
  include SeasonScoped

  before_action :set_season
  before_action :require_host

  def create
    tribe = @season.tribes.build(tribe_params)

    if tribe.save
      redirect_to season_path(@season), notice: "Tribe added."
    else
      redirect_to season_path(@season), alert: tribe.errors.full_messages.to_sentence
    end
  end

  def destroy
    @season.tribes.find(params[:id]).destroy
    redirect_to season_path(@season), notice: "Tribe removed."
  end

  private

  def tribe_params
    params.require(:tribe).permit(:name)
  end
end
