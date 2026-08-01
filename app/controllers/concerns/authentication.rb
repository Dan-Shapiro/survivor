module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
    before_action :require_login
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_login, **options
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    session[:return_to_after_login] = request.fullpath if request.get? || request.head?
    redirect_to login_path, alert: "Please log in first."
  end

  def login_as(user)
    reset_session
    session[:user_id] = user.id
  end

  def redirect_path_after_login
    session.delete(:return_to_after_login) || root_path
  end
end
