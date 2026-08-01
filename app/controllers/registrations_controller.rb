class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      login_as(@user)
      redirect_to_after_signup
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :display_name, :pin, :pin_confirmation)
  end

  # Signing up via an invite link (see InvitesController) carries the invite
  # code through so the new account lands straight in that season, instead
  # of at a bare account with nowhere to go.
  def redirect_to_after_signup
    if params[:invite_code].present?
      redirect_to join_path(params[:invite_code]), notice: "Account created — joining the season now."
    else
      redirect_to root_path, notice: "Account created."
    end
  end
end
