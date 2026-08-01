class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate_pin(params[:pin])
      login_as(user)
      redirect_to redirect_path_after_login, notice: "Welcome back, #{user.display_name}."
    else
      flash.now[:alert] = "Incorrect email or PIN."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out."
  end
end
