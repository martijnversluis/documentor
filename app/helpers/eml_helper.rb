module EmlHelper
  def parse_eml(blob)
    content = blob.download
    mail = Mail.new(content)

    {
      from: mail.from&.join(", "),
      to: mail.to&.join(", "),
      cc: mail.cc&.join(", "),
      subject: mail.subject,
      date: mail.date,
      body: extract_body(mail)
    }
  end

  private

  def extract_body(mail)
    if mail.multipart?
      # Prefer HTML, fall back to plain text
      html_part = mail.html_part
      text_part = mail.text_part

      if html_part
        html_part.decoded.force_encoding("UTF-8")
      elsif text_part
        simple_format(text_part.decoded.force_encoding("UTF-8"))
      else
        mail.parts.first&.decoded&.force_encoding("UTF-8") || ""
      end
    else
      body = mail.body.decoded.force_encoding("UTF-8")
      if mail.content_type&.include?("text/html")
        body
      else
        simple_format(body)
      end
    end
  rescue => e
    "<p class='text-red-500'>Kon email body niet lezen: #{e.message}</p>"
  end
end
