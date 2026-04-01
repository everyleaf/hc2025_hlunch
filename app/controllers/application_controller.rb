class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :basic_authenticate

  private

  def basic_authenticate
    return unless ENV["BASIC_AUTH_USERNAME"].present? && ENV["BASIC_AUTH_PASSWORD"].present?

    authenticate_or_request_with_http_basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV["BASIC_AUTH_USERNAME"]) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV["BASIC_AUTH_PASSWORD"])
    end
  end
end
