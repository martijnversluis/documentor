namespace :documents do
  desc "Extract text from all documents that don't have content_text yet"
  task extract_text: :environment do
    documents = Document.unscoped.where(content_text: nil).joins(:file_attachment)

    total = documents.count
    puts "Found #{total} documents to process"

    documents.find_each.with_index do |document, index|
      print "\rProcessing #{index + 1}/#{total}: #{document.name.truncate(40)}..."

      text = TextExtractionService.new(document).extract

      if text.present?
        document.update_column(:content_text, text)
        print " #{text.length} chars"
      else
        print " no text"
      end
    end

    puts "\nDone!"
  end

  desc "Enqueue PreprocessImageVariantsJob for every existing image attachment"
  task preprocess_image_variants: :environment do
    image_blobs = ActiveStorage::Blob.where(
      content_type: ActiveStorage.variable_content_types | ActiveStorage.web_image_content_types,
    )

    total = image_blobs.count
    puts "Enqueueing variant preprocessing for #{total} image blobs"

    image_blobs.find_each.with_index do |blob, index|
      PreprocessImageVariantsJob.perform_later(blob.id)
      print "\rQueued #{index + 1}/#{total}"
    end

    puts "\nDone!"
  end

  desc "Re-extract text for all documents (overwrites existing)"
  task reextract_text: :environment do
    documents = Document.unscoped.joins(:file_attachment)

    total = documents.count
    puts "Found #{total} documents to process"

    documents.find_each.with_index do |document, index|
      print "\rProcessing #{index + 1}/#{total}: #{document.name.truncate(40)}..."

      text = TextExtractionService.new(document).extract

      if text.present?
        document.update_column(:content_text, text)
        print " #{text.length} chars"
      else
        print " no text"
      end
    end

    puts "\nDone!"
  end
end
