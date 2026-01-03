class TurnCredentials
  class ApiError < StandardError; end

  CLOUDFLARE_API_URL = "https://rtc.live.cloudflare.com/v1/turn/keys/%s/credentials/generate"
  TTL = 86400

  def self.fetch
    Rails.cache.fetch("turn_credentials", expires_in: 1.hour) do
      fetch_from_cloudflare
    end
  end

  def self.fetch_from_cloudflare
    uri = URI(CLOUDFLARE_API_URL % ENV.fetch("CLOUDFLARE_TURN_KEY_ID"))

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV.fetch("CLOUDFLARE_TURN_API_TOKEN")}"
    request["Content-Type"] = "application/json"
    request.body = { ttl: TTL }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Cloudflare API returned #{response.code}"
    end

    parse_response(response.body)
  end

  def self.parse_response(body)
    data = JSON.parse(body)
    ice_servers = data["iceServers"]

    stun_urls = ice_servers["urls"].select { |url| url.start_with?("stun:") }
    turn_urls = ice_servers["urls"].select { |url| url.start_with?("turn:") }

    turn_urls_with_transport = turn_urls.flat_map do |url|
      [ "#{url}?transport=udp", "#{url}?transport=tcp" ]
    end

    {
      "iceServers" => [
        { "urls" => stun_urls },
        {
          "urls" => turn_urls_with_transport,
          "username" => ice_servers["username"],
          "credential" => ice_servers["credential"]
        }
      ]
    }
  end

  private_class_method :fetch_from_cloudflare, :parse_response
end
