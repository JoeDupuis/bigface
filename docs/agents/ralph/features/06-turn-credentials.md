# TURN Credentials API

## Description

Provide an API endpoint that fetches short-lived TURN/STUN credentials from Cloudflare. The WebRTC client uses these to establish connections through NAT.

## Behavior

### Endpoint

`GET /turn_credentials`

Returns JSON with ICE server configuration for WebRTC.

### Cloudflare API

Cloudflare's TURN API: `https://rtc.live.cloudflare.com/v1/turn/keys/:key_id/credentials/generate`

Request:
```bash
curl -X POST "https://rtc.live.cloudflare.com/v1/turn/keys/$TURN_KEY_ID/credentials/generate" \
  -H "Authorization: Bearer $TURN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ttl": 86400}'
```

Response:
```json
{
  "iceServers": {
    "urls": ["stun:stun.cloudflare.com:3478", "turn:turn.cloudflare.com:3478"],
    "username": "...",
    "credential": "..."
  }
}
```

### Our Endpoint Response

```json
{
  "iceServers": [
    {
      "urls": ["stun:stun.cloudflare.com:3478"]
    },
    {
      "urls": ["turn:turn.cloudflare.com:3478?transport=udp", "turn:turn.cloudflare.com:3478?transport=tcp"],
      "username": "...",
      "credential": "..."
    }
  ]
}
```

## Routes

```ruby
resource :turn_credentials, only: [:show]
```

## Environment Variables

- `CLOUDFLARE_TURN_KEY_ID` - The key ID from Cloudflare dashboard
- `CLOUDFLARE_TURN_API_TOKEN` - API token with TURN permissions

## Tests

### Controller Tests

**GET /turn_credentials when logged in**
- Given: logged-in user
- And: valid Cloudflare credentials configured
- When: requesting /turn_credentials
- Then: returns 200
- And: response contains iceServers array
- And: iceServers contains STUN and TURN entries

**GET /turn_credentials when not logged in**
- Given: not logged in
- When: requesting /turn_credentials
- Then: returns 401

**GET /turn_credentials when Cloudflare fails**
- Given: logged-in user
- And: Cloudflare API returns error
- When: requesting /turn_credentials
- Then: returns 503
- And: response contains error message

### Model/Service Tests

**TurnCredentials.fetch returns ice servers**
- Given: valid Cloudflare credentials
- When: calling TurnCredentials.fetch
- Then: returns hash with iceServers

**TurnCredentials.fetch raises on API error**
- Given: Cloudflare returns 401
- When: calling TurnCredentials.fetch
- Then: raises TurnCredentials::ApiError

## Implementation Notes

- Create `app/models/turn_credentials.rb` (not an ActiveRecord model, just a plain Ruby class)
- Use `Net::HTTP` or `Faraday` for the API call
- Cache credentials briefly (they're valid for 24h, but refresh every hour)
- Add credentials to Rails credentials or ENV

```ruby
# app/models/turn_credentials.rb
class TurnCredentials
  class ApiError < StandardError; end

  def self.fetch
    # Make API call to Cloudflare
    # Return formatted iceServers array
  end
end
```

For tests, stub the Cloudflare API call:

```ruby
# In test
stub_request(:post, /cloudflare/)
  .to_return(body: { iceServers: { ... } }.to_json)
```

## Dependencies

None - standalone feature.
