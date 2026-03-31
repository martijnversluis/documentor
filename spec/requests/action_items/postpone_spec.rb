require 'rails_helper'

RSpec.describe "ActionItems#postpone", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:dossier) { Dossier.create!(name: "Test Dossier") }
  let(:work_dossier) { Dossier.create!(name: "Werk Dossier", work_dossier: true) }

  describe "PATCH /action_items/:id/postpone" do
    it "moves a regular item to tomorrow" do
      item = dossier.action_items.create!(description: "Gewoon item", due_date: Date.current)

      patch postpone_action_item_path(item), as: :turbo_stream

      item.reload
      expect(item.due_date).to eq(Date.tomorrow)
    end

    it "moves a work dossier item to the next workday" do
      travel_to Date.new(2026, 3, 27) do # vrijdag
        item = work_dossier.action_items.create!(description: "Werk item", due_date: Date.current)

        patch postpone_action_item_path(item), as: :turbo_stream

        item.reload
        expect(item.due_date).to eq(Date.new(2026, 3, 30)) # maandag
      end
    end

    it "moves a work dossier item to tomorrow on a weekday" do
      travel_to Date.new(2026, 3, 25) do # woensdag
        item = work_dossier.action_items.create!(description: "Werk item", due_date: Date.current)

        patch postpone_action_item_path(item), as: :turbo_stream

        item.reload
        expect(item.due_date).to eq(Date.new(2026, 3, 26)) # donderdag
      end
    end

    it "returns a turbo stream response that removes the item" do
      item = dossier.action_items.create!(description: "Test", due_date: Date.current)

      patch postpone_action_item_path(item), as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include("remove")
    end
  end
end
