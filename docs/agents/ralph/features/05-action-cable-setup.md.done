# Action Cable Channel Setup

## Description

Set up the Action Cable infrastructure for real-time communication. This includes a per-user notification channel and a per-call signaling channel.

## Behavior

### UserNotificationChannel

Each user subscribes to their personal notification channel when they load the app. This channel receives:
- Incoming call alerts
- Call state updates (answered elsewhere, missed, etc.)

### CallChannel

When a call is initiated, both parties subscribe to a call-specific channel. This channel handles:
- WebRTC signaling (SDP offers/answers, ICE candidates)
- Call state changes (answered, declined, ended)

## Channels

### UserNotificationChannel

```ruby
class UserNotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

Broadcast to it via:
```ruby
UserNotificationChannel.broadcast_to(user, { type: "incoming_call", call_id: 123 })
```

### CallChannel

```ruby
class CallChannel < ApplicationCable::Channel
  def subscribed
    @call = Call.find(params[:call_id])
    # Only allow caller or recipient to subscribe
    if authorized?
      stream_for @call
    else
      reject
    end
  end

  def receive(data)
    # Relay signaling messages to the other party
    CallChannel.broadcast_to(@call, data.merge(from: current_user.id))
  end
end
```

## Connection Authentication

Action Cable connections must be authenticated. Use the session to identify the user.

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Use the same session-based auth as the app
      if (session = Session.find_by(id: cookies.signed[:session_id]))
        session.user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

## Tests

### Channel Tests

**UserNotificationChannel subscribes for current user**
- Given: authenticated cable connection for user Alice
- When: subscribing to UserNotificationChannel
- Then: subscription succeeds
- And: streams for Alice

**UserNotificationChannel rejects unauthenticated**
- Given: unauthenticated cable connection
- When: subscribing to UserNotificationChannel
- Then: subscription rejected

**CallChannel subscribes for authorized users**
- Given: call between Alice and Bob
- And: authenticated connection for Alice
- When: subscribing to CallChannel with call_id
- Then: subscription succeeds

**CallChannel rejects unauthorized users**
- Given: call between Alice and Bob
- And: authenticated connection for Charlie
- When: subscribing to CallChannel with call_id
- Then: subscription rejected

**CallChannel relays messages**
- Given: call between Alice and Bob
- And: both subscribed to CallChannel
- When: Alice sends signaling data
- Then: Bob receives it with from: Alice.id

### Connection Tests

**Connection authenticates from session**
- Given: valid session cookie
- When: connecting to Action Cable
- Then: current_user is set

**Connection rejects without session**
- Given: no session cookie
- When: connecting to Action Cable
- Then: connection rejected

## Implementation Notes

- Update `app/channels/application_cable/connection.rb` for auth
- Create `app/channels/user_notification_channel.rb`
- Create `app/channels/call_channel.rb`
- CallChannel needs the Call model to exist, but we can stub it for now or create it in this feature
- For testing Action Cable, use `ActionCable::Channel::TestCase`

## JavaScript Setup

Create JavaScript to subscribe to UserNotificationChannel on page load:

```javascript
// app/javascript/channels/user_notification_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("UserNotificationChannel", {
  received(data) {
    // Handle incoming notifications
    if (data.type === "incoming_call") {
      // Show incoming call UI (handled in later feature)
      window.dispatchEvent(new CustomEvent("incoming-call", { detail: data }))
    }
  }
})
```

## Dependencies

None - this is infrastructure that other features build on.
