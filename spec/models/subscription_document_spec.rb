require 'rails_helper'

RSpec.describe SubscriptionDocument, type: :model do
  it "belongs to subscription and document" do
    subscription = Subscription.create!(name: "Test")
    doc = Document.create!(name: "Test Doc")
    link = SubscriptionDocument.create!(subscription: subscription, document: doc)

    expect(link.subscription).to eq(subscription)
    expect(link.document).to eq(doc)
  end

  it "enforces uniqueness of document per subscription" do
    subscription = Subscription.create!(name: "Test")
    doc = Document.create!(name: "Test Doc")
    SubscriptionDocument.create!(subscription: subscription, document: doc)

    duplicate = SubscriptionDocument.new(subscription: subscription, document: doc)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:document_id]).to be_present
  end

  it "allows same document on different subscriptions" do
    sub1 = Subscription.create!(name: "Sub 1")
    sub2 = Subscription.create!(name: "Sub 2")
    doc = Document.create!(name: "Test Doc")

    SubscriptionDocument.create!(subscription: sub1, document: doc)
    link2 = SubscriptionDocument.new(subscription: sub2, document: doc)
    expect(link2).to be_valid
  end
end
