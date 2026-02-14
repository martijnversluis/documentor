class TextExtractionService
  MAX_TEXT_LENGTH = 100_000 # Limit stored text to 100KB

  def initialize(document)
    @document = document
  end

  def extract
    return nil unless @document.file.attached?

    text = case content_type
           when "application/pdf"
             extract_from_pdf
           when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
             extract_from_docx
           when "message/rfc822"
             extract_from_eml
           when "text/plain"
             extract_from_text
           when "text/html"
             extract_from_html
           else
             nil
           end

    return nil if text.blank?

    # Clean and truncate the text
    text = clean_text(text)
    text.truncate(MAX_TEXT_LENGTH)
  rescue => e
    Rails.logger.error "Text extraction failed for document #{@document.id}: #{e.message}"
    nil
  end

  private

  def content_type
    @document.file.content_type
  end

  def download_file
    @document.file.download
  end

  def extract_from_pdf
    require "pdf-reader"

    content = download_file
    reader = PDF::Reader.new(StringIO.new(content))

    text_parts = []
    reader.pages.each do |page|
      text_parts << page.text
    end

    text_parts.join("\n\n")
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    Rails.logger.warn "Could not extract text from PDF #{@document.id}: #{e.message}"
    nil
  end

  def extract_from_docx
    require "docx"

    content = download_file
    doc = Docx::Document.open(StringIO.new(content))

    text_parts = []
    doc.paragraphs.each do |p|
      text_parts << p.text if p.text.present?
    end

    text_parts.join("\n")
  rescue => e
    Rails.logger.warn "Could not extract text from DOCX #{@document.id}: #{e.message}"
    nil
  end

  def extract_from_eml
    content = download_file
    mail = Mail.new(content)

    parts = []
    parts << "Van: #{mail.from&.join(', ')}" if mail.from.present?
    parts << "Aan: #{mail.to&.join(', ')}" if mail.to.present?
    parts << "Onderwerp: #{mail.subject}" if mail.subject.present?
    parts << ""

    # Get the body - prefer plain text
    body = if mail.multipart?
             mail.text_part&.decoded || mail.html_part&.decoded&.then { |html| strip_html(html) }
           else
             mail.body.decoded
           end

    parts << body if body.present?

    parts.join("\n")
  rescue => e
    Rails.logger.warn "Could not extract text from EML #{@document.id}: #{e.message}"
    nil
  end

  def extract_from_text
    download_file.force_encoding("UTF-8")
  rescue => e
    Rails.logger.warn "Could not extract text from file #{@document.id}: #{e.message}"
    nil
  end

  def extract_from_html
    strip_html(download_file)
  rescue => e
    Rails.logger.warn "Could not extract text from HTML #{@document.id}: #{e.message}"
    nil
  end

  def strip_html(html)
    # Remove script and style tags with content
    html = html.gsub(/<script[^>]*>.*?<\/script>/mi, " ")
    html = html.gsub(/<style[^>]*>.*?<\/style>/mi, " ")
    # Remove all HTML tags
    html = html.gsub(/<[^>]+>/, " ")
    # Decode HTML entities
    html = CGI.unescapeHTML(html)
    html
  end

  def clean_text(text)
    return nil if text.blank?

    # Normalize whitespace
    text = text.gsub(/\r\n?/, "\n")
    # Remove excessive newlines
    text = text.gsub(/\n{3,}/, "\n\n")
    # Remove excessive spaces
    text = text.gsub(/[ \t]+/, " ")
    # Strip leading/trailing whitespace from lines
    text = text.lines.map(&:strip).join("\n")
    # Final strip
    text.strip
  end
end
