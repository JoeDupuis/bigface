require "test_helper"

class TurnCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    ENV["CLOUDFLARE_TURN_KEY_ID"] = "test_key_id"
    ENV["CLOUDFLARE_TURN_API_TOKEN"] = "test_api_token"
  end

  test "GET /turn_credentials when logged in returns iceServers" do
    sign_in_as(users(:one))
    stub_cloudflare_success

    get turn_credentials_path, as: :json

    assert_response :ok
    json = response.parsed_body
    assert json.key?("iceServers")
    assert_equal 2, json["iceServers"].length

    stun_entry = json["iceServers"][0]
    turn_entry = json["iceServers"][1]

    assert stun_entry["urls"].any? { |url| url.start_with?("stun:") }
    assert turn_entry["urls"].any? { |url| url.start_with?("turn:") }
    assert turn_entry.key?("username")
    assert turn_entry.key?("credential")
  end

  test "GET /turn_credentials when not logged in returns 401" do
    get turn_credentials_path, as: :json

    assert_response :unauthorized
  end

  test "GET /turn_credentials when Cloudflare fails returns 503" do
    sign_in_as(users(:one))
    stub_cloudflare_failure

    get turn_credentials_path, as: :json

    assert_response :service_unavailable
    json = response.parsed_body
    assert json.key?("error")
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
