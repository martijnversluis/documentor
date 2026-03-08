require 'rails_helper'

RSpec.describe "Subscriptions", type: :request do
  let!(:subscription) { Subscription.create!(name: "Netflix", cost_cents: 1599, cost_frequency: "monthly") }

  describe "GET /subscriptions" do
    it "shows active subscriptions" do
      get subscriptions_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Netflix")
    end

    it "excludes archived subscriptions" do
      subscription.archive!
      get subscriptions_path
      expect(response.body).not_to include("Netflix")
    end
  end

  describe "GET /subscriptions/archived" do
    it "shows archived subscriptions" do
      subscription.archive!
      get archived_subscriptions_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Netflix")
    end
  end

  describe "GET /subscriptions/new" do
    it "renders the new form" do
      get new_subscription_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /subscriptions" do
    it "creates a subscription" do
      expect {
        post subscriptions_path, params: { subscription: { name: "Spotify", cost_cents: 999, cost_frequency: "monthly" } }
      }.to change(Subscription, :count).by(1)
      expect(response).to redirect_to(subscription_path(Subscription.last))
    end

    it "renders new on invalid params" do
      post subscriptions_path, params: { subscription: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /subscriptions/:id" do
    it "shows the subscription" do
      get subscription_path(subscription)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Netflix")
    end
  end

  describe "GET /subscriptions/:id/edit" do
    it "renders the edit form" do
      get edit_subscription_path(subscription)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /subscriptions/:id" do
    it "updates the subscription" do
      patch subscription_path(subscription), params: { subscription: { name: "Netflix Premium" } }
      expect(response).to redirect_to(subscription_path(subscription))
      expect(subscription.reload.name).to eq("Netflix Premium")
    end

    it "renders edit on invalid params" do
      patch subscription_path(subscription), params: { subscription: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /subscriptions/:id" do
    it "destroys the subscription" do
      expect {
        delete subscription_path(subscription)
      }.to change(Subscription, :count).by(-1)
      expect(response).to redirect_to(subscriptions_path)
    end
  end

  describe "PATCH /subscriptions/:id/archive" do
    it "archives the subscription" do
      patch archive_subscription_path(subscription)
      expect(subscription.reload).to be_archived
      expect(response).to redirect_to(subscriptions_path)
    end
  end

  describe "PATCH /subscriptions/:id/unarchive" do
    it "unarchives the subscription" do
      subscription.archive!
      patch unarchive_subscription_path(subscription)
      expect(subscription.reload).not_to be_archived
      expect(response).to redirect_to(subscription_path(subscription))
    end
  end
end
