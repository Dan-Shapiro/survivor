class AnnouncementsController < ApplicationController
  include SeasonScoped
  include EmailNotifications

  before_action :set_season
  before_action :require_season_member

  def index
    @sent = @season.announcements.sent.order(sent_at: :desc)
    @is_host = @season.host_id == current_user.id
    @pending = @season.announcements.where(sent_at: nil).order(:scheduled_at) if @is_host
    @rounds = @season.rounds.order(:number) if @is_host
  end

  def create
    unless @season.host_id == current_user.id
      redirect_to season_announcements_path(@season), alert: "Only the host can do that."
      return
    end

    round = @season.rounds.find(params[:round_id]) if params[:round_id].present?
    scheduled_at = Time.zone.parse(params[:scheduled_at]) if params[:scheduled_at].present?

    announcement = @season.announce!(created_by: current_user, announcement_type: params[:announcement_type],
      body: params[:body], round: round, scheduled_at: scheduled_at)

    if announcement.sent_at?
      @season.season_memberships.each do |membership|
        notify_safely { SeasonMailer.announcement_sent(announcement: announcement, membership: membership).deliver_now }
      end
    end

    redirect_to season_announcements_path(@season), notice: "Announcement saved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to season_announcements_path(@season), alert: e.message
  end
end
