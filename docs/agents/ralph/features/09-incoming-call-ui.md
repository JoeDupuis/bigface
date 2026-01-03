# Incoming Call UI

## Description

When a user receives a call, all their logged-in browser sessions show an incoming call notification with Answer and Decline buttons.

## Behavior

### Incoming Call Display

When UserNotificationChannel receives "incoming_call":
1. Show a full-screen or modal incoming call UI
2. Display caller's name: "Alice is calling..."
3. Show Answer (green) and Decline (red) buttons
4. Play a ring sound (optional for MVP)

### Answering

1. User clicks Answer
2. POST to /calls/:id/answer
3. Server marks call as active, records which session answered
4. User is redirected to call page (or page updates via Turbo)
5. All other recipient sessions receive "call_answered" and dismiss their UI

### Declining

1. User clicks Decline
2. POST to /calls/:id/decline
3. Server marks call as declined
4. All recipient sessions dismiss incoming call UI
5. Caller's page shows "Call declined"

## Routes

```ruby
resources :calls, only: [:create, :show] do
  member do
    post :answer
    post :decline
  end
end
```

## Tests

### Controller Tests

**POST /calls/:id/answer as recipient**
- Given: ringing call from Alice to Bob
- And: logged in as Bob
- When: posting to /calls/:id/answer
- Then: call status is "active"
- And: call.started_at is set
- And: call.answered_by_session is Bob's current session
- And: redirects to call page

**POST /calls/:id/answer as wrong user**
- Given: ringing call from Alice to Bob
- And: logged in as Alice (the caller)
- When: posting to /calls/:id/answer
- Then: returns forbidden/error
- And: call status unchanged

**POST /calls/:id/answer when not ringing**
- Given: call with status "ended"
- And: logged in as recipient
- When: posting to /calls/:id/answer
- Then: returns error
- And: call status unchanged

**POST /calls/:id/decline as recipient**
- Given: ringing call from Alice to Bob
- And: logged in as Bob
- When: posting to /calls/:id/decline
- Then: call status is "declined"
- And: call.ended_at is set
- And: redirects to contacts or shows message

**POST /calls/:id/decline as wrong user**
- Given: ringing call from Alice to Bob
- And: logged in as Alice
- When: posting to /calls/:id/decline
- Then: returns forbidden/error

### Broadcast Tests

**Answering broadcasts to call channel**
- Given: ringing call
- When: recipient answers
- Then: CallChannel broadcasts { type: "answered", answered_by: session_id }

**Declining broadcasts to call channel**
- Given: ringing call
- When: recipient declines
- Then: CallChannel broadcasts { type: "declined" }

### JavaScript/Integration Tests

**Incoming call notification appears**
- Given: user Bob is on the contacts page
- When: Alice calls Bob
- Then: incoming call UI appears
- And: shows "Alice is calling..."
- And: shows Answer and Decline buttons

**Answering dismisses notification and shows call**
- Given: incoming call notification showing
- When: clicking Answer
- Then: notification dismissed
- And: redirected to call page

**Declining dismisses notification**
- Given: incoming call notification showing
- When: clicking Decline
- Then: notification dismissed
- And: stays on current page

## Implementation Notes

### Incoming Call Component

Create a Stimulus controller that listens for incoming call events:

```javascript
// app/javascript/controllers/incoming_call_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "callerName"]
  static values = { callId: Number }

  connect() {
    window.addEventListener("incoming-call", this.handleIncomingCall.bind(this))
  }

  handleIncomingCall(event) {
    const { call_id, caller_name } = event.detail
    this.callIdValue = call_id
    this.callerNameTarget.textContent = `${caller_name} is calling...`
    this.containerTarget.classList.remove("hidden")
  }

  answer() {
    // POST to /calls/:id/answer
    fetch(`/calls/${this.callIdValue}/answer`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    }).then(response => {
      if (response.redirected) {
        window.location.href = response.url
      }
    })
  }

  decline() {
    fetch(`/calls/${this.callIdValue}/decline`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    }).then(() => {
      this.containerTarget.classList.add("hidden")
    })
  }
}
```

### Layout Component

Add incoming call container to application layout:

```erb
# In application layout
<div data-controller="incoming-call"
     data-incoming-call-target="container"
     class="hidden fixed inset-0 bg-black/80 flex items-center justify-center z-50">
  <div class="text-center text-white">
    <p class="text-2xl mb-8" data-incoming-call-target="callerName"></p>
    <div class="space-x-4">
      <button data-action="incoming-call#answer"
              class="bg-green-500 px-8 py-4 rounded-full text-xl">
        Answer
      </button>
      <button data-action="incoming-call#decline"
              class="bg-red-500 px-8 py-4 rounded-full text-xl">
        Decline
      </button>
    </div>
  </div>
</div>
```

## Dependencies

- 05-action-cable-setup (need channels)
- 07-call-model (need Call with answer!/decline!)
- 08-call-initiation (need incoming call broadcast)
