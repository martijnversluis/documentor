require "rails_helper"

RSpec.describe Document do
  describe "after_commit :preprocess_image_variants" do
    around do |example|
      previous = Bullet.enable?
      Bullet.enable = false
      example.run
    ensure
      Bullet.enable = previous
    end

    it "enqueues PreprocessImageVariantsJob when an image is attached" do
      document = create(:document)
      blob = build_blob(filename: "photo.png", content_type: "image/png")

      expect { document.file.attach(blob) }
        .to have_enqueued_job(PreprocessImageVariantsJob).with(blob.id)
    end

    it "enqueues PreprocessImageVariantsJob for HEIC attachments" do
      document = create(:document)
      blob = build_blob(filename: "photo.heic", content_type: "image/heic")

      expect { document.file.attach(blob) }.to have_enqueued_job(PreprocessImageVariantsJob)
    end

    it "does not enqueue PreprocessImageVariantsJob for non-image attachments" do
      document = create(:document)
      blob = build_blob(filename: "contract.pdf", content_type: "application/pdf")

      expect { document.file.attach(blob) }.not_to have_enqueued_job(PreprocessImageVariantsJob)
    end
  end

  def build_blob(filename:, content_type:)
    ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("spec/fixtures/files/sample.png").open,
      filename: filename,
      content_type: content_type,
      identify: false,
    )
  end
end
