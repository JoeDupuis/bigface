# Call Timeout

## Description

If nobody answers a call within 30 seconds, the call is automatically marked as missed. This prevents calls from ringing forever.

## Behavior

### Timeout Flow

1. Call is created (status: ringing)
2. Background job is scheduled for 30 seconds later
3. If call is still ringing after 30 seconds:
   - Status changes to "missed"
   - Caller sees "No answer" message
   - Recipient's incoming call UI dismisses
4. If call was already answered/declined/cancelled, job does nothing

### Caller Experience

When call times out:
1. "Calling..." changes to "No answer"
2. After 2 seconds, redirect to contacts

### Recipient Experience

When call times out:
1. Incoming call UI dismisses
2. No redirect (they stay where they were)

## Routes

No new routes - this is a background job.

## Tests

### Job Tests

**CallTimeoutJob marks ringing call as missed**
- Given: call created 30+ seconds ago with status ringing
- When: job runs
- Then: call status is "missed"
- And: call.ended_at is set

**CallTimeoutJob ignores answered calls**
- Given: call with status active
- When: job runs
- Then: call status unchanged

**CallTimeoutJob ignores ended calls**
- Given: call with status ended
- When: job runs
- Then: call status unchanged

**CallTimeoutJob ignores declined calls**
- Given: call with status declined
- When: job runs
- Then: call status unchanged

### Broadcast Tests

**Timeout broadcasts to caller**
- Given: ringing call times out
- Then: CallChannel broadcasts { type: "timeout" }

**Timeout broadcasts to recipient**
- Given: ringing call times out
- Then: UserNotificationChannel for recipient receives { type: "call_timeout", call_id }

### Integration Tests

**Call timeout after 30 seconds**
1. Alice calls Bob
2. Bob does not answer
3. Wait 30 seconds (use travel_to or adjust timeout for test)
4. Alice sees "No answer"
5. Bob's incoming call UI dismisses
6. Call status is "missed"

## Implementation Notes

### Job

```ruby
# app/jobs/call_timeout_job.rb
class CallTimeoutJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return unless call&.ringing?

    call.timeout!
  end
end
```

### Call Model Updates

```ruby
class Call < ApplicationRecord
  RING_TIMEOUT = 30.seconds

  after_create_commit :schedule_timeout

  def timeout!
    return unless ringing?

    update!(status: :missed, ended_at: Time.current)
    broadcast_timeout
  end

  private

  def schedule_timeout
    CallTimeoutJob.set(wait: RING_TIMEOUT).perform_later(id)
  end

  def broadcast_timeout
    CallChannel.broadcast_to(self, { type: "timeout" })
    UserNotificationChannel.broadcast_to(recipient, {
      type: "call_timeout",
      call_id: id
    })
  end
end
```

### JavaScript Updates

Handle timeout in call controller:

```javascript
// In call_controller.js handleSignaling
case "timeout":
  this.statusTarget.textContent = "No answer"
  setTimeout(() => {
    window.location.href = "/contacts"
  }, 2000)
  break
```

Handle timeout in incoming call controller:

```javascript
// In incoming_call_controller.js
window.addEventListener("call-timeout", (event) => {
  if (event.detail.call_id === this.callIdValue) {
    this.dismiss()
  }
})
```

Update user notification channel:

```javascript
case "call_timeout":
  window.dispatchEvent(new CustomEvent("call-timeout", { detail: data }))
  break
```

### Testing with Short Timeout

For testing, you might want to make the timeout configurable:

```ruby
class Call < ApplicationRecord
  RING_TIMEOUT = Rails.env.test? ? 2.seconds : 30.seconds
end
```

Or use `travel_to` in tests to simulate time passing.

## Dependencies

- 08-call-initiation (need calls to be created)
- 09-incoming-call-ui (need UI to dismiss on timeout)
