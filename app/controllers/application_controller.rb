class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'geoweb'

  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || stored_location_for(resource) ||
      root_path
  end

  protect_from_forgery with: :exception
  def new_session_path(scope)
    new_user_session_path
  end

  def route_not_found
    render file: 'public/404.html', status: :not_found
  end
end
