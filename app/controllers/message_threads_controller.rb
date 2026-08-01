class MessageThreadsController < ApplicationController
  include SeasonScoped

  before_action :set_season
  before_action :require_season_member
  before_action :set_membership

  def index
    @public_thread = @season.public_thread
    @threads = @membership.message_threads.where(kind: %w[dm group]).includes(:season_memberships)
    @other_members = @season.season_memberships.where.not(id: @membership.id).where.not(role: "spectator").includes(:user)
  end

  def show
    @thread = @season.message_threads.find(params[:id])

    unless @thread.visible_to?(@membership)
      redirect_to season_message_threads_path(@season), alert: "You don't have access to that conversation."
      return
    end

    @thread.mark_read!(@membership)
    @messages = @thread.messages.includes(sender_membership: :user).order(:created_at)
  end

  def create
    if params[:kind] == "dm"
      other = @season.season_memberships.find(params[:other_membership_id])
      thread = @season.find_or_create_dm!(between: [ @membership, other ])
    else
      participants = @season.season_memberships.where(id: Array(params[:participant_ids]))
      thread = @season.create_group!(name: params[:name], creator: @membership, participants: participants)
    end

    redirect_to season_message_thread_path(@season, thread)
  rescue RuntimeError => e
    redirect_to season_message_threads_path(@season), alert: e.message
  end

  private

  def set_membership
    @membership = @season.season_memberships.find_by(user: current_user)
  end
end
