require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  # Don't auto-sign-in for these tests
  before { reset!  }

  describe "GET /login" do
    it "shows the login form" do
      get login_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Inloggen")
    end

    it "redirects to root if already authenticated" do
      sign_in
      get login_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /login" do
    it "authenticates with valid credentials" do
      post login_path, params: { username: ENV["AUTH_USERNAME"], password: ENV["AUTH_PASSWORD"] }
      expect(response).to redirect_to(root_path)
    end

    it "rejects invalid credentials" do
      post login_path, params: { username: "wrong", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Ongeldige gebruikersnaam of wachtwoord")
    end

    it "redirects to the original URL after login" do
      get dossiers_path
      expect(response).to redirect_to(login_path)

      post login_path, params: { username: ENV["AUTH_USERNAME"], password: ENV["AUTH_PASSWORD"] }
      expect(response).to redirect_to(dossiers_path)
    end
  end

  describe "DELETE /logout" do
    it "logs out and redirects to login" do
      sign_in
      delete logout_path
      expect(response).to redirect_to(login_path)

      get root_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "unauthenticated access" do
    it "redirects to login" do
      get root_path
      expect(response).to redirect_to(login_path)
    end
  end
end
