# Call Initiation

## Description

Users can start a call by clicking on a contact. This creates a Call record and broadcasts to all of the recipient's logged-in devices.

## Behavior

### Starting a Call

1. User clicks on a contact name in their contact list
2. POST to /calls with recipient_id
3. System creates Call record (status: ringing)
4. System broadcasts "incoming_call" to recipient's UserNotificationChannel
5. Caller is redirected to the call page
6. Caller's page shows "Calling {name}..." and their own video preview

### Call Page

`/calls/:id`

Shows:
- Video preview (local camera)
- "Calling {recipient.name}..." message
- "Cancel" button to hang up before answered

## Routes

```ruby
resources :calls, only: [:create, :show]
```

## Tests

### Controller Tests

**POST /calls with valid recipient**
- Given: logged-in user Alice with contact Bob
- When: posting to /calls with recipient_id: Bob.id
- Then: creates Call record with caller: Alice, recipient: Bob, status: ringing
- And: redirects to call show page

**POST /calls with non-contact**
- Given: logged-in user Alice
- And: user Charlie who is NOT a contact
- When: posting to /calls with recipient_id: Charlie.id
- Then: does not create call
- And: returns error

**POST /calls when already in a ringing call**
- Given: logged-in user Alice with existing ringing call
- When: posting to /calls
- Then: does not create another call
- And: returns error

**GET /calls/:id as caller**
- Given: call from Alice to Bob
- And: logged in as Alice
- When: visiting /calls/:id
- Then: shows call page
- And: shows "Calling Bob..."

**GET /calls/:id as recipient**
- Given: call from Alice to Bob
- And: logged in as Bob
- When: visiting /calls/:id
- Then: shows call page (for answering)

**GET /calls/:id as unrelated user**
- Given: call between Alice and Bob
- And: logged in as Charlie
- When: visiting /calls/:id
- Then: returns 404

### Broadcast Tests

**Creating call broadcasts to recipient**
- Given: logged-in Alice with contact Bob
- When: Alice creates a call to Bob
- Then: UserNotificationChannel broadcasts to Bob
- And: broadcast contains type: "incoming_call", call_id, caller_name

### Integration Tests

**Start call flow**
1. Alice logs in
2. Alice visits /contacts
3. Alice clicks on Bob's name (or call button)
4. Call is created
5. Alice sees call page with "Calling Bob..."
6. Bob's session receives incoming_call notification

## Implementation Notes

- Add call button to contact list (link_to or button_to that POSTs)
- CallsController#create creates Call and broadcasts
- Use `after_create_commit` callback on Call to broadcast

```ruby
class Call < ApplicationRecord
  after_create_commit :broadcast_to_recipient

  private

  def broadcast_to_recipient
    UserNotificationChannel.broadcast_to(recipient, {
      type: "incoming_call",
      call_id: id,
      caller_name: caller.name,
      caller_id: caller.id
    })
  end
end
```

### Call Page View

```erb
# app/views/calls/show.html.erb
<div id="call-container" data-call-id="<%= @call.id %>" data-role="<%= call_role %>">
  <div id="local-video-container">
    <video id="local-video" autoplay muted playsinline></video>
  </div>

  <% if @call.ringing? && current_user == @call.caller %>
    <p>Calling <%= @call.recipient.name %>...</p>
    <%= button_to "Cancel", call_path(@call), method: :delete %>
  <% end %>

  <div id="remote-video-container" style="display: none;">
    <video id="remote-video" autoplay playsinline></video>
  </div>
</div>
```

### JavaScript (Stimulus Controller)

Create a Stimulus controller that:
1. Requests camera/mic permissions
2. Shows local video preview
3. Subscribes to CallChannel for signaling
4. Handles call state changes

Basic structure (full WebRTC in later feature):

```javascript
// app/javascript/controllers/call_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { callId: Number, role: String }

  connect() {
    this.startLocalVideo()
    this.subscribeToChannel()
  }

  async startLocalVideo() {
    this.localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true })
    this.element.querySelector("#local-video").srcObject = this.localStream
  }

  subscribeToChannel() {
    // Subscribe to CallChannel (implemented in later feature)
  }
}
```

## Dependencies

- 04-contact-list (need contact list UI to add call button)
- 05-action-cable-setup (need UserNotificationChannel)
- 07-call-model (need Call model)
