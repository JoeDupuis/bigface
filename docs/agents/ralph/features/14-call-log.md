# Call Log

## Description

Users can view their call history showing who they called, who called them, and the outcome (answered, missed, declined).

## Behavior

### Call Log Page

`/calls` (index)

Shows:
- List of calls (recent first)
- For each call:
  - Contact name (caller or recipient, whichever isn't current user)
  - Direction indicator (incoming/outgoing)
  - Outcome: "Answered" / "Missed" / "Declined"
  - Duration (if answered)
  - Timestamp
- Click on a call to call that person again (link to their contact)

### Filtering (optional for MVP)

- All calls
- Missed calls only

## Routes

```ruby
resources :calls, only: [:index, :create, :show] do
  # existing member routes
end
```

## Tests

### Controller Tests

**GET /calls shows call history**
- Given: logged-in user Alice with calls:
  - Outgoing to Bob (answered, 5 min)
  - Incoming from Charlie (missed)
  - Outgoing to Bob (declined)
- When: visiting /calls
- Then: shows all 3 calls
- And: shows Bob, Charlie, Bob names
- And: shows directions (outgoing, incoming, outgoing)
- And: shows outcomes (Answered, Missed, Declined)
- And: shows duration for answered call

**GET /calls excludes other users' calls**
- Given: logged-in user Alice
- And: call between Bob and Charlie (Alice not involved)
- When: visiting /calls
- Then: does not show Bob-Charlie call

**GET /calls orders by most recent**
- Given: 3 calls created at different times
- When: visiting /calls
- Then: most recent appears first

**GET /calls when not logged in**
- Given: not logged in
- When: visiting /calls
- Then: redirects to login

### View Tests

**Call log shows duration for completed calls**
- Given: call that lasted 5 minutes 30 seconds
- When: rendering call in list
- Then: shows "5:30" duration

**Call log shows nothing for missed/declined**
- Given: missed call
- When: rendering call in list
- Then: does not show duration

**Call log links to contact**
- Given: call with contact Bob
- When: rendering call in list
- Then: Bob's name links to start a new call

## Implementation Notes

### Controller

```ruby
class CallsController < ApplicationController
  def index
    @calls = current_user_calls.order(created_at: :desc)
  end

  private

  def current_user_calls
    Call.where(caller: current_user)
        .or(Call.where(recipient: current_user))
        .where.not(status: :ringing) # Don't show active ringing calls
  end
end
```

### View

```erb
# app/views/calls/index.html.erb
<h1>Call History</h1>

<% if @calls.any? %>
  <ul>
    <% @calls.each do |call| %>
      <li>
        <% other_user = call.caller == current_user ? call.recipient : call.caller %>
        <% direction = call.caller == current_user ? "Outgoing" : "Incoming" %>

        <%= link_to other_user.name, new_call_path(recipient_id: other_user.id) %>
        <span class="direction"><%= direction %></span>
        <span class="outcome"><%= call.status.humanize %></span>

        <% if call.ended? && call.started_at %>
          <span class="duration"><%= format_duration(call.ended_at - call.started_at) %></span>
        <% end %>

        <span class="time"><%= time_ago_in_words(call.created_at) %> ago</span>
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No calls yet.</p>
<% end %>

<%= link_to "Back to contacts", contacts_path %>
```

### Helper

```ruby
# app/helpers/calls_helper.rb
module CallsHelper
  def format_duration(seconds)
    seconds = seconds.to_i
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    format("%d:%02d", minutes, remaining_seconds)
  end
end
```

### Navigation

Add link to call log from contacts page:

```erb
<%= link_to "Call History", calls_path %>
```

## Dependencies

- 07-call-model (need Call records to exist)
