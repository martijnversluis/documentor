describe "ActionItems#show" do
  describe "GET /action_items/:id" do
    context "when the action item has a party" do
      let(:party) do
        Party.create!(
          name: "Klant X",
          phone: "020-1234567",
          email: "info@klant-x.example",
          address: "Kerkstraat 1",
          postal_code: "1234 AB",
          city: "Amsterdam",
          website: "https://klant-x.example"
        )
      end

      it "renders the contact details for the linked party" do
        item = ActionItem.create!(description: "Bellen met klant", party: party)

        get action_item_path(item)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Klant X")
        expect(response.body).to include("020-1234567")
        expect(response.body).to include("info@klant-x.example")
        expect(response.body).to include("mailto:info@klant-x.example")
        expect(response.body).to include("tel:020-1234567")
      end

      it "shows earlier action items for the same party as history" do
        older = ActionItem.create!(
          description: "Eerder gesprek gevoerd",
          party: party,
          notes: "Klant vroeg om offerte",
          completed_at: 2.weeks.ago
        )
        current = ActionItem.create!(description: "Follow-up bellen", party: party)

        get action_item_path(current)

        expect(response.body).to include("Eerdere actiepunten voor Klant X")
        expect(response.body).to include(older.description)
        expect(response.body).to include("Klant vroeg om offerte")
      end

      it "does not include the current action item in its own history" do
        item = ActionItem.create!(description: "Enige actie", party: party)

        get action_item_path(item)

        expect(response.body).not_to include("Eerdere actiepunten voor Klant X")
      end
    end

    context "when the action item has no party" do
      it "does not render a contact or history section" do
        item = ActionItem.create!(description: "Standalone")

        get action_item_path(item)

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Eerdere actiepunten voor")
      end
    end
  end
end
