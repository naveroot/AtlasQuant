class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :analytics_events_json

  private

  def track_analytics_event(event, properties = {})
    @analytics_events ||= []
    @analytics_events << { event: event, properties: properties }
  end

  def analytics_events_json
    (@analytics_events || []).to_json
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to new_session_path, alert: "Please sign in to continue."
  end
end
