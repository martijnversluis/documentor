require "rails_helper"

describe "Mail#promote" do
  describe "GET /mail/promote/new" do
    it "renders the modal form with prefilled description and notes" do
      get new_mail_promote_path,
        params: { thread_id: "abc123", description: "[Mail van X] Hi", notes: "https://example" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("[Mail van X] Hi")
      expect(response.body).to include("abc123")
    end
  end

  describe "POST /mail/promote" do
    it "creates an ActionItem from form params and renders a turbo stream" do
      expect {
        post mail_promote_path,
          params: {
            thread_id: "abc123",
            action_item: {
              description: "Beantwoord X",
              notes: "https://mail",
              due_date: Date.current,
              context: ""
            }
          },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(ActionItem, :count).by(1)

      expect(response).to have_http_status(:success)
      item = ActionItem.last
      expect(item.description).to eq("Beantwoord X")
      expect(item.notes).to eq("https://mail")
      expect(item.context).to be_blank
    end

    it "assigns the chosen dossier and context" do
      dossier = create(:dossier)
      context = TaskContext.first || TaskContext.create!(name: "computer")

      post mail_promote_path,
        params: {
          action_item: {
            description: "Do it",
            dossier_id: dossier.id,
            context: context.name,
            due_date: Date.current
          }
        },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      item = ActionItem.last
      expect(item.dossier).to eq(dossier)
      expect(item.context).to eq(context.name)
    end

    it "re-renders the modal form on validation failure" do
      post mail_promote_path,
        params: {
          thread_id: "abc123",
          action_item: { description: "", due_date: Date.current }
        },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("modal")
    end
  end
end
