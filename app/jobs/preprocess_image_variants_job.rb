class PreprocessImageVariantsJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: "preprocess_image_variants"

  HEIC_CONTENT_TYPES = %w[image/heic image/heif].freeze

  THUMBNAIL_SIZES = [
    [40, 40],
    [80, 80],
    [320, 320],
  ].freeze

  def self.transformations_for(blob)
    sized = THUMBNAIL_SIZES.map { |size| { resize_to_limit: size } }

    if blob.content_type.in?(HEIC_CONTENT_TYPES)
      sized.map { |s| s.merge(format: :jpeg) } + [{ format: :jpeg }]
    else
      sized
    end
  end

  def perform(blob_id)
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob&.image?

    self.class.transformations_for(blob).each do |transformations|
      blob.variant(transformations).processed
    end
  end

end
