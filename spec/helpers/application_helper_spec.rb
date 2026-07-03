require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#document_thumbnail_tag" do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/sample.png").open,
        filename: "sample.png",
        content_type: "image/png",
        identify: false
      )
    end

    let(:attachment) { double("Attachment", attached?: true, blob: blob, previewable?: false) }

    before { allow(helper).to receive(:url_for) { |arg| "/rails/blob/#{arg.class}" } }

    it "returns nil for an unattached attachment" do
      expect(helper.document_thumbnail_tag(double(attached?: false), size: [40, 40])).to be_nil
    end

    context "when the variant is already processed" do
      it "renders an image_tag pointing at the processed variant" do
        blob.variant(resize_to_limit: [40, 40]).processed
        html = helper.document_thumbnail_tag(attachment, size: [40, 40], class: "w-8 h-8")

        expect(html).to include("<img")
        expect(html).to include("w-8 h-8")
      end
    end

    context "when the variant has not been processed yet" do
      it "renders a placeholder div and enqueues the preprocess job" do
        expect {
          html = helper.document_thumbnail_tag(attachment, size: [40, 40], class: "w-8 h-8")
          expect(html).to include("<div")
          expect(html).to include("w-8 h-8")
          expect(html).to include("bg-gray-100")
          expect(html).not_to include("<img")
        }.to have_enqueued_job(PreprocessImageVariantsJob).with(blob.id)
      end
    end
  end
end
