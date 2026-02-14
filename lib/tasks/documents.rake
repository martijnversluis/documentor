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
