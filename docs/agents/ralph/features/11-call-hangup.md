# Call Hangup

## Description

Either party can end an active call. This properly closes the WebRTC connection and updates the Call record.

## Behavior

### Ending a Call

1. User clicks "End Call" button
2. POST to /calls/:id/hangup (or DELETE /calls/:id)
3. Server marks call as ended
4. Server broadcasts "hangup" via CallChannel
5. Both parties' WebRTC connections close
6. Both parties redirect to contacts page

### Canceling Before Answer

If caller clicks "Cancel" while call is still ringing:
1. POST to /calls/:id/hangup
2. Server marks call as ended (or missed?)
3. Server broadcasts to recipient's UserNotificationChannel
4. Recipient's incoming call UI dismisses
5. Caller redirects to contacts

## Routes

```ruby
resources :calls, only: [:create, :show] do
  member do
    post :answer
    post :decline
    post :hangup  # Or use DELETE :destroy
  end
end
```

## Tests

### Controller Tests

**POST /calls/:id/hangup as caller during ringing**
- Given: ringing call from Alice to Bob
- And: logged in as Alice
- When: posting to /calls/:id/hangup
- Then: call status is "ended"
- And: call.ended_at is set
- And: redirects to contacts

**POST /calls/:id/hangup as caller during active**
- Given: active call from Alice to Bob
- And: logged in as Alice
- When: posting to /calls/:id/hangup
- Then: call status is "ended"
- And: call.ended_at is set
- And: redirects to contacts

**POST /calls/:id/hangup as recipient during active**
- Given: active call from Alice to Bob
- And: logged in as Bob
- When: posting to /calls/:id/hangup
- Then: call status is "ended"
- And: redirects to contacts

**POST /calls/:id/hangup as unrelated user**
- Given: call between Alice and Bob
- And: logged in as Charlie
- When: posting to /calls/:id/hangup
- Then: returns 404

### Broadcast Tests

**Hangup broadcasts to CallChannel**
- Given: active call
- When: either party hangs up
- Then: CallChannel broadcasts { type: "hangup" }

**Cancel during ringing broadcasts to recipient**
- Given: ringing call
- When: caller cancels
- Then: UserNotificationChannel broadcasts { type: "call_cancelled", call_id }
- And: recipient's incoming call UI dismisses

### Integration Tests

**End call flow**
1. Alice and Bob are in an active call
2. Alice clicks "End Call"
3. Call ends for both
4. Both redirected to contacts

**Cancel call before answer**
1. Alice calls Bob
2. Bob sees incoming call
3. Alice clicks "Cancel"
4. Bob's incoming call UI dismisses
5. Alice is back on contacts

## Implementation Notes

### Call Model Updates

```ruby
class Call < ApplicationRecord
  def hangup!
    case status
    when "ringing"
      update!(status: :ended, ended_at: Time.current)
      broadcast_cancellation
    when "active"
      update!(status: :ended, ended_at: Time.current)
      broadcast_hangup
    end
  end

  private

  def broadcast_hangup
    CallChannel.broadcast_to(self, { type: "hangup" })
  end

  def broadcast_cancellation
    UserNotificationChannel.broadcast_to(recipient, {
      type: "call_cancelled",
      call_id: id
    })
  end
end
```

### Controller

```ruby
class CallsController < ApplicationController
  def hangup
    @call = find_authorized_call
    @call.hangup!
    redirect_to contacts_path, notice: "Call ended"
  end

  private

  def find_authorized_call
    Call.where(caller: current_user).or(Call.where(recipient: current_user))
        .find(params[:id])
  end
end
```

### JavaScript Updates

Add hangup button handling:

```javascript
// In call_controller.js
endCall() {
  fetch(`/calls/${this.callIdValue}/hangup`, {
    method: "POST",
    headers: {
      "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
    }
  })
}
```

Handle incoming hangup in channel:
```javascript
case "hangup":
  this.webrtc.close()
  window.location.href = "/contacts"
  break
```

### Updated Call View

```erb
<% if @call.active? %>
  <button data-action="call#endCall"
          class="bg-red-500 px-8 py-4 rounded-full">
    End Call
  </button>
<% elsif @call.ringing? && current_user == @call.caller %>
  <button data-action="call#endCall"
          class="bg-gray-500 px-8 py-4 rounded-full">
    Cancel
  </button>
<% end %>
```

## Dependencies

- 10-webrtc-connection (need active call to hang up)
