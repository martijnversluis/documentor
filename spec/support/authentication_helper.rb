module AuthenticationHelper
  def sign_in
    post login_path, params: { username: ENV["AUTH_USERNAME"], password: ENV["AUTH_PASSWORD"] }
  end
end

module FeatureAuthenticationHelper
  def sign_in
    page.driver.post(Rails.application.routes.url_helpers.login_path,
                     username: ENV["AUTH_USERNAME"],
                     password: ENV["AUTH_PASSWORD"])
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
  config.include FeatureAuthenticationHelper, type: :feature

  config.before(:each, type: :request) { sign_in }
  config.before(:each, type: :feature) { sign_in }
end
