class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :register_push_device

  private

  def register_push_device
    return unless Current.user
    token = cookies[:push_token]
    device = ApplicationPushDevice.find_or_initialize_by(token: token)
    return if token.blank? || device.persisted? && device.token == session[:registered_push_token]

    device.update!(platform: "google", owner: Current.user)
    session[:registered_push_token] = token
  end
end
