class MessagesController < ApplicationController
  include SeasonScoped

  before_action :set_season

  def create
    membership = @season.season_memberships.find_by(user: current_user)
    thread = @season.message_threads.find(params[:message_thread_id])

    thread.post!(sender: membership, body: params[:body])
    thread.mark_read!(membership)
    redirect_to season_message_thread_path(@season, thread)
  rescue RuntimeError => e
    redirect_to season_message_thread_path(@season, thread), alert: e.message
  end
end
