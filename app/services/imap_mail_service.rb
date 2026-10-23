require "net/imap"

class ImapMailService
  class AuthorizationError < StandardError; end
  class ConnectionError < StandardError; end

  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10

  def initialize(imap_account)
    @account = imap_account
  end

  def unread_messages(max_results: 20)
    with_imap do |imap|
      imap.examine(@account.folder)
      uids = imap.uid_search(["UNSEEN"])
      return [] if uids.empty?

      recent_uids = uids.last(max_results).reverse
      fetched = imap.uid_fetch(recent_uids, ["ENVELOPE", "INTERNALDATE"])
      return [] if fetched.nil?

      fetched.map { |item| build_message(item) }
    end
  end

  def mark_as_read(uid)
    with_imap do |imap|
      imap.select(@account.folder)
      imap.uid_store(Integer(uid), "+FLAGS", [:Seen])
    end
  end

  private

  def build_message(fetch_data)
    envelope = fetch_data.attr["ENVELOPE"]
    from = envelope.from&.first
    {
      thread_id: fetch_data.attr["UID"].to_s,
      message_id: envelope.message_id,
      subject: envelope.subject.to_s,
      from: format_address(from),
      date: safe_parse_date(envelope.date || fetch_data.attr["INTERNALDATE"]),
      message_count: 1
    }
  end

  def format_address(addr)
    return "Onbekend" if addr.nil?
    display = addr.name.presence || addr.mailbox
    "#{display} <#{addr.mailbox}@#{addr.host}>"
  end

  def safe_parse_date(value)
    return nil if value.blank?
    Time.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def with_imap
    imap = Net::IMAP.new(
      @account.host,
      port: @account.port,
      ssl: true,
      open_timeout: OPEN_TIMEOUT,
      idle_response_timeout: READ_TIMEOUT
    )
    begin
      imap.login(@account.username, @account.password)
    rescue Net::IMAP::NoResponseError, Net::IMAP::BadResponseError => e
      raise AuthorizationError, "IMAP login failed voor #{@account.username}: #{e.message}"
    end

    yield imap
  rescue Errno::ECONNREFUSED, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
    raise ConnectionError, "Kon niet verbinden met #{@account.host}: #{e.message}"
  ensure
    begin
      imap&.logout
    rescue StandardError
      # ignore
    end
    begin
      imap&.disconnect
    rescue StandardError
      # ignore
    end
  end
end
