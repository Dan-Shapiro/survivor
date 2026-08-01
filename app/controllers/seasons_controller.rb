class SeasonsController < ApplicationController
  include SeasonScoped

  MEMBER_ACTIONS = %i[start merge start_jury_phase reveal_finale].freeze

  before_action :set_season, only: %i[show] + MEMBER_ACTIONS
  before_action :require_season_member, only: %i[show] + MEMBER_ACTIONS
  before_action :require_host, only: MEMBER_ACTIONS

  def new
    @season = Season.new
  end

  def create
    @season = Season.new(season_params)
    @season.host = current_user

    if @season.save
      redirect_to season_path(@season), notice: "Season created. Share the invite link to add players."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @tribes = @season.tribes.order(:name)
    @memberships = @season.season_memberships.includes(:user, :tribe)
    @jurors = @season.jurors.includes(:user)
  end

  # Transitions setup -> active once the 12-player minimum is met (see
  # Season#startable? / docs/GAME_DESIGN.md#scoring--win-condition).
  def start
    if @season.startable?
      @season.update!(status: "active")
      redirect_to season_path(@season), notice: "Season started."
    else
      redirect_to season_path(@season),
        alert: "Need at least #{Season::MINIMUM_PLAYERS} active players to start (have #{@season.active_players.count})."
    end
  end

  def merge
    @season.merge!
    redirect_to season_path(@season), notice: "Tribes have merged."
  rescue RuntimeError => e
    redirect_to season_path(@season), alert: e.message
  end

  def start_jury_phase
    @season.start_jury_phase!
    redirect_to season_path(@season), notice: "Jury voting is open."
  rescue RuntimeError => e
    redirect_to season_path(@season), alert: e.message
  end

  def reveal_finale
    winner_membership = @season.season_memberships.find(params[:winner_id]) if params[:winner_id].present?
    winner = @season.reveal_finale!(winner: winner_membership)
    redirect_to season_path(@season), notice: "#{winner.user.display_name} wins the season!"
  rescue RuntimeError => e
    redirect_to season_path(@season), alert: e.message
  end

  private

  def season_params
    params.require(:season).permit(:name, :jury_size)
  end
end
