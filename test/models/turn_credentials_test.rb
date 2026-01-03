require "test_helper"

class TurnCredentialsTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    ENV["CLOUDFLARE_TURN_KEY_ID"] = "test_key_id"
    ENV["CLOUDFLARE_TURN_API_TOKEN"] = "test_api_token"
  end

  test "fetch returns ice servers" do
    stub_cloudflare_success

    result = TurnCredentials.fetch

    assert_kind_of Hash, result
    assert result.key?("iceServers")
    assert_equal 2, result["iceServers"].length

    stun_entry = result["iceServers"][0]
    assert stun_entry["urls"].all? { |url| url.start_with?("stun:") }

    turn_entry = result["iceServers"][1]
    assert turn_entry["urls"].all? { |url| url.start_with?("turn:") }
    assert turn_entry.key?("username")
    assert turn_entry.key?("credential")
  end

  test "fetch raises ApiError on API error" do
    stub_cloudflare_failure

    assert_raises TurnCredentials::ApiError do
      TurnCredentials.fetch
    end
  end

  private

  def stub_cloudflare_success
    response_body = {
      iceServers: {
        urls: [ "stun:stun.cloudflare.com:3478", "turn:turn.cloudflare.com:3478" ],
        username: "test_username",
        credential: "test_credential"
      }
    }.to_json

    stub_request(:post, /rtc\.live\.cloudflare\.com/)
      .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
  end

  def stub_cloudflare_failure
    stub_request(:post, /rtc\.live\.cloudflare\.com/)
      .to_return(status: 401, body: { error: "Unauthorized" }.to_json)
  end
end
