# Disable CRL checking which can cause issues on macOS
# Error: "certificate verify failed (unable to get certificate CRL)"
#
# Configure Faraday (used by Google API clients) to skip SSL verification in development
if Rails.env.development?
  require "faraday"

  Faraday.default_connection_options = Faraday::ConnectionOptions.new(
    ssl: { verify: false }
  )
end
