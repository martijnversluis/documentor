module AuthenticationHelper
  def sign_in
    post login_path, params: { username: ENV["AUTH_USERNAME"], password: ENV["AUTH_PASSWORD"] }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request

  config.before(:each, type: :request) do
    sign_in
  end
end
