require 'rails_helper'

RSpec.describe "API Authentication", type: :request do
  before { reset! }

  describe "without credentials" do
    it "returns 401" do
      get api_dossiers_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "with invalid credentials" do
    it "returns 401" do
      get api_dossiers_path, as: :json,
          headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "wrong") }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "with valid credentials" do
    it "returns 200" do
      get api_dossiers_path, as: :json,
          headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["AUTH_USERNAME"], ENV["AUTH_PASSWORD"]) }
      expect(response).to have_http_status(:success)
    end
  end
end
