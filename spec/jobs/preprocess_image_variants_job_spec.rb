require "rails_helper"

RSpec.describe PreprocessImageVariantsJob do
  it "generates the three standard thumbnails for a non-HEIC image blob" do
    blob = create_blob(content_type: "image/png")
    variant = stub_variant(blob)

    described_class.perform_now(blob.id)

    expect(blob).to have_received(:variant).with(resize_to_limit: [40, 40])
    expect(blob).to have_received(:variant).with(resize_to_limit: [80, 80])
    expect(blob).to have_received(:variant).with(resize_to_limit: [320, 320])
    expect(variant).to have_received(:processed).exactly(3).times
  end

  it "also generates a JPEG full-size variant for HEIC blobs" do
    blob = create_blob(content_type: "image/heic")
    variant = stub_variant(blob)

    described_class.perform_now(blob.id)

    expect(blob).to have_received(:variant).with(resize_to_limit: [40, 40], format: :jpeg)
    expect(blob).to have_received(:variant).with(resize_to_limit: [80, 80], format: :jpeg)
    expect(blob).to have_received(:variant).with(resize_to_limit: [320, 320], format: :jpeg)
    expect(blob).to have_received(:variant).with(format: :jpeg)
    expect(variant).to have_received(:processed).exactly(4).times
  end

  it "skips non-image blobs" do
    blob = create_blob(content_type: "application/pdf")
    stub_variant(blob)

    described_class.perform_now(blob.id)

    expect(blob).not_to have_received(:variant)
  end

  it "is a no-op when the blob no longer exists" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end

  def create_blob(content_type:)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("spec/fixtures/files/sample.png").open,
      filename: "sample",
      content_type: content_type,
      identify: false,
    )
    allow(ActiveStorage::Blob).to receive(:find_by).with(id: blob.id).and_return(blob)
    blob
  end

  def stub_variant(blob)
    variant = instance_double(ActiveStorage::VariantWithRecord, processed: true)
    allow(blob).to receive(:variant).and_return(variant)
    variant
  end
end
