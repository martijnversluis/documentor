require "net/http"
require "ipaddr"
require "resolv"

class EmbedCheckController < ApplicationController
  PRIVATE_RANGES = [
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  def check
    uri = parse_uri(params[:url].to_s)

    if uri.nil? || private_address?(uri.host)
      render json: { embeddable: false }
      return
    end

    render json: { embeddable: embeddable?(safe_fetch_headers(uri)) }
  end

  def parse_uri(url)
    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP) && uri.host.present?
    uri
  rescue URI::InvalidURIError
    nil
  end

  def safe_fetch_headers(uri)
    fetch_headers(uri)
  rescue StandardError => e
    Rails.logger.info "EmbedCheck fetch failed for #{uri}: #{e.class}: #{e.message}"
    nil
  end

  private

  def fetch_headers(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 3, read_timeout: 3) do |http|
      response = http.head(uri.request_uri, "User-Agent" => "Documentor-EmbedCheck/1.0")
      return response if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)

      req = Net::HTTP::Get.new(uri.request_uri, "User-Agent" => "Documentor-EmbedCheck/1.0", "Range" => "bytes=0-0")
      http.request(req)
    end
  end

  def embeddable?(response)
    return true unless response

    xfo = response["x-frame-options"]
    return false if xfo && xfo.upcase.match?(/\A(DENY|SAMEORIGIN)/)

    csp = response["content-security-policy"]
    return false if csp && csp.match?(/frame-ancestors\s+(?:'none'|"none"|none)(?:[\s;]|\z)/i)

    true
  end

  def private_address?(host)
    Resolv.getaddresses(host).any? do |ip_str|
      ip = IPAddr.new(ip_str)
      PRIVATE_RANGES.any? { |range| range.include?(ip) }
    end
  rescue StandardError
    true
  end
end
