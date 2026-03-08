module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_login
    before_action :authenticate_api
    before_action :set_default_format

    private

    def authenticate_api
      authenticate_or_request_with_http_basic("Documentor API") do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, ENV["AUTH_USERNAME"].to_s) &
          ActiveSupport::SecurityUtils.secure_compare(password, ENV["AUTH_PASSWORD"].to_s)
      end
    end

    def set_default_format
      request.format = :json
    end
  end
end
