# Multi-Device Ring Dismiss

## Description

When a call is answered on one device, all other devices showing the incoming call should dismiss their notification. This prevents confusion and multiple answer attempts.

## Behavior

### Scenario

1. Bob has 3 browser tabs/devices logged in
2. Alice calls Bob
3. All 3 show incoming call notification
4. Bob answers on device 1
5. Devices 2 and 3 immediately dismiss notification
6. Only device 1 proceeds to the call

### How It Works

When a call is answered:
1. Server broadcasts to UserNotificationChannel (all recipient devices)
2. Broadcast contains: `{ type: "call_answered", call_id: X }`
3. All devices with that call_id showing dismiss it
4. Only the device that answered navigates to call page

## Tests

### Broadcast Tests

**Answer broadcasts call_answered to user channel**
- Given: ringing call from Alice to Bob
- When: Bob answers
- Then: UserNotificationChannel for Bob receives { type: "call_answered", call_id }

### JavaScript Tests

**call_answered dismisses incoming call UI**
- Given: incoming call UI showing for call_id 123
- When: receiving { type: "call_answered", call_id: 123 }
- Then: incoming call UI is hidden

**call_answered ignores different call_id**
- Given: incoming call UI showing for call_id 123
- When: receiving { type: "call_answered", call_id: 456 }
- Then: incoming call UI remains visible

### Integration Tests

**Multi-device answer dismisses others**
1. Bob has two sessions (simulate with two browser contexts or Capybara's using_session)
2. Alice calls Bob
3. Both Bob sessions show incoming call
4. Bob answers in session 1
5. Session 2's incoming call UI dismisses
6. Session 1 shows call page

## Implementation Notes

### Updated Call Model

```ruby
class Call < ApplicationRecord
  def answer!(session)
    raise InvalidTransition unless ringing?

    transaction do
      update!(
        status: :active,
        started_at: Time.current,
        answered_by_session: session
      )
      broadcast_answered
      broadcast_to_call_channel
    end
  end

  private

  def broadcast_answered
    UserNotificationChannel.broadcast_to(recipient, {
      type: "call_answered",
      call_id: id
    })
  end

  def broadcast_to_call_channel
    CallChannel.broadcast_to(self, {
      type: "answered",
      answered_by_session_id: answered_by_session_id
    })
  end
end
```

### Updated Incoming Call Controller

```javascript
// app/javascript/controllers/incoming_call_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "callerName"]
  static values = { callId: Number }

  connect() {
    window.addEventListener("incoming-call", this.handleIncomingCall.bind(this))
    window.addEventListener("call-answered", this.handleCallAnswered.bind(this))
    window.addEventListener("call-cancelled", this.handleCallCancelled.bind(this))
  }

  disconnect() {
    window.removeEventListener("incoming-call", this.handleIncomingCall.bind(this))
    window.removeEventListener("call-answered", this.handleCallAnswered.bind(this))
    window.removeEventListener("call-cancelled", this.handleCallCancelled.bind(this))
  }

  handleIncomingCall(event) {
    const { call_id, caller_name } = event.detail
    this.callIdValue = call_id
    this.callerNameTarget.textContent = `${caller_name} is calling...`
    this.containerTarget.classList.remove("hidden")
  }

  handleCallAnswered(event) {
    if (event.detail.call_id === this.callIdValue) {
      this.dismiss()
    }
  }

  handleCallCancelled(event) {
    if (event.detail.call_id === this.callIdValue) {
      this.dismiss()
    }
  }

  dismiss() {
    this.containerTarget.classList.add("hidden")
    this.callIdValue = null
  }

  // ... answer() and decline() methods
}
```

### Updated User Notification Channel

```javascript
// app/javascript/channels/user_notification_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("UserNotificationChannel", {
  received(data) {
    switch (data.type) {
      case "incoming_call":
        window.dispatchEvent(new CustomEvent("incoming-call", { detail: data }))
        break
      case "call_answered":
        window.dispatchEvent(new CustomEvent("call-answered", { detail: data }))
        break
      case "call_cancelled":
        window.dispatchEvent(new CustomEvent("call-cancelled", { detail: data }))
        break
    }
  }
})
```

## Dependencies

- 09-incoming-call-ui (need incoming call UI to dismiss)
