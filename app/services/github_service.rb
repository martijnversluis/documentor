class GithubService
  API_BASE = "https://api.github.com".freeze
  OAUTH_AUTHORIZE_URL = "https://github.com/login/oauth/authorize".freeze
  OAUTH_TOKEN_URL = "https://github.com/login/oauth/access_token".freeze

  class AuthorizationError < StandardError; end

  def initialize(github_account = nil)
    @account = github_account
  end

  # Generate OAuth authorization URL
  def self.authorization_url(redirect_uri)
    params = {
      client_id: credentials[:client_id],
      redirect_uri: redirect_uri,
      scope: "notifications repo",
      state: SecureRandom.hex(16)
    }
    "#{OAUTH_AUTHORIZE_URL}?#{params.to_query}"
  end

  # Exchange authorization code for access token
  def self.exchange_code(code, redirect_uri)
    uri = URI(OAUTH_TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    request.set_form_data(
      client_id: credentials[:client_id],
      client_secret: credentials[:client_secret],
      code: code,
      redirect_uri: redirect_uri
    )

    response = http.request(request)
    data = JSON.parse(response.body, symbolize_names: true)

    if data[:error]
      raise AuthorizationError, data[:error_description] || data[:error]
    end

    data[:access_token]
  end

  # Get authenticated user info
  def self.user_info(access_token)
    uri = URI("#{API_BASE}/user")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Accept"] = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"

    response = http.request(request)
    JSON.parse(response.body, symbolize_names: true)
  end

  # Fetch unread notifications
  def notifications
    return [] unless @account

    uri = URI("#{API_BASE}/notifications")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@account.access_token}"
    request["Accept"] = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"

    response = http.request(request)

    if response.code == "401"
      raise AuthorizationError, "GitHub token is invalid or expired"
    end

    JSON.parse(response.body, symbolize_names: true)
  end

  # Fetch issues assigned to the user
  def assigned_issues
    return [] unless @account

    # Search for open issues assigned to the authenticated user
    query = "is:issue is:open assignee:@me"
    search_items(query)
  end

  # Fetch open PRs created by or assigned to the user
  def my_pull_requests
    return [] unless @account

    # Search for open PRs authored by or assigned to the authenticated user
    query = "is:pr is:open author:@me"
    authored = search_items(query)

    query = "is:pr is:open assignee:@me"
    assigned = search_items(query)

    # Merge and deduplicate by URL
    (authored + assigned).uniq { |pr| pr[:html_url] }
  end

  # Fetch all GitHub data for dashboard
  def dashboard_data
    {
      notifications: notifications,
      issues: assigned_issues,
      pull_requests: my_pull_requests
    }
  end

  # Mark a notification thread as read
  def mark_as_read(thread_id)
    return unless @account

    uri = URI("#{API_BASE}/notifications/threads/#{thread_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    request = Net::HTTP::Patch.new(uri)
    request["Authorization"] = "Bearer #{@account.access_token}"
    request["Accept"] = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"

    http.request(request)
  end

  # Convert notification to action item description
  def self.notification_to_description(notification)
    repo = notification[:repository][:full_name]
    subject = notification[:subject]
    type_label = case subject[:type]
                 when "PullRequest" then "PR"
                 when "Issue" then "Issue"
                 when "Release" then "Release"
                 when "Discussion" then "Discussion"
                 else subject[:type]
                 end

    reason_label = case notification[:reason]
                   when "review_requested" then "review requested"
                   when "mention" then "mentioned"
                   when "author" then "your #{type_label.downcase}"
                   when "assign" then "assigned"
                   when "comment" then "commented"
                   when "ci_activity" then "CI"
                   else nil
                   end

    parts = ["[#{repo}]"]
    parts << "(#{reason_label})" if reason_label
    parts << subject[:title]

    parts.join(" ")
  end

  # Get the web URL for a notification
  def self.notification_url(notification)
    api_url = notification[:subject][:url]
    return nil unless api_url

    # Convert API URL to web URL
    # https://api.github.com/repos/owner/repo/pulls/123 -> https://github.com/owner/repo/pull/123
    api_url
      .gsub("api.github.com/repos", "github.com")
      .gsub("/pulls/", "/pull/")
      .gsub("/issues/", "/issues/")
  end

  def self.credentials
    AppCredentials.github
  end

  private

  def search_items(query)
    uri = URI("#{API_BASE}/search/issues")
    uri.query = URI.encode_www_form(q: query, per_page: 20, sort: "updated", order: "desc")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@account.access_token}"
    request["Accept"] = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"

    response = http.request(request)

    if response.code == "401"
      raise AuthorizationError, "GitHub token is invalid or expired"
    end

    data = JSON.parse(response.body, symbolize_names: true)
    data[:items] || []
  end
end
