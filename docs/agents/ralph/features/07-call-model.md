# Call Model

## Description

The Call model tracks video call state from initiation through completion. It stores who called whom, the current status, and timing information.

## Behavior

### Call Lifecycle

1. **Created** → status: `ringing`
2. **Answered** → status: `active`, started_at set
3. **Ended normally** → status: `ended`, ended_at set
4. **Not answered (timeout)** → status: `missed`, ended_at set
5. **Declined** → status: `declined`, ended_at set

### Rules

- A user can only have one active/ringing outgoing call at a time
- Caller and recipient must be contacts
- Only recipient can answer/decline
- Either party can end an active call

## Models

**Call** - see `docs/agents/data-model.md` for full schema.

Key fields:
- `caller_id` → User
- `recipient_id` → User
- `status` - enum: ringing, active, ended, missed, declined
- `started_at` - when answered
- `ended_at` - when call ended
- `answered_by_session_id` → Session

## Tests

### Model Tests

**Call requires caller**
- Given: call without caller
- When: validating
- Then: fails with "Caller must exist"

**Call requires recipient**
- Given: call without recipient
- When: validating
- Then: fails with "Recipient must exist"

**Call defaults to ringing status**
- Given: new call
- When: checking status
- Then: status is "ringing"

**Call#answer! transitions to active**
- Given: call with status ringing
- When: calling answer!(session)
- Then: status is "active"
- And: started_at is set
- And: answered_by_session is set

**Call#answer! fails if not ringing**
- Given: call with status ended
- When: calling answer!(session)
- Then: raises InvalidTransition error

**Call#end! transitions to ended**
- Given: call with status active
- When: calling end!
- Then: status is "ended"
- And: ended_at is set

**Call#decline! transitions to declined**
- Given: call with status ringing
- When: calling decline!
- Then: status is "declined"
- And: ended_at is set

**Call#miss! transitions to missed**
- Given: call with status ringing
- When: calling miss!
- Then: status is "missed"
- And: ended_at is set

**Call scopes**
- `Call.active` returns calls with status active
- `Call.ringing` returns calls with status ringing

**User can only have one ringing outgoing call**
- Given: user with existing ringing call
- When: creating another call as caller
- Then: validation fails

**Caller and recipient must be contacts**
- Given: two users who are NOT contacts
- When: creating call between them
- Then: validation fails with "must be a contact"

### Association Tests

**Call belongs to caller**
- Given: call with caller Alice
- When: accessing call.caller
- Then: returns Alice

**Call belongs to recipient**
- Given: call with recipient Bob
- When: accessing call.recipient
- Then: returns Bob

**User has many outgoing_calls**
- Given: user with 3 calls as caller
- When: accessing user.outgoing_calls
- Then: returns 3 calls

**User has many incoming_calls**
- Given: user with 2 calls as recipient
- When: accessing user.incoming_calls
- Then: returns 2 calls

## Implementation Notes

- Create migration for calls table
- Use string column for status with validation (or Rails enum)
- Add state transition methods that enforce valid transitions
- Create custom `InvalidTransition` error class

```ruby
class Call < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :caller, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :answered_by_session, class_name: "Session", optional: true

  enum :status, { ringing: "ringing", active: "active", ended: "ended", missed: "missed", declined: "declined" }

  validates :caller_id, uniqueness: { scope: :status, conditions: -> { ringing } }
  validate :caller_and_recipient_are_contacts

  def answer!(session)
    raise InvalidTransition unless ringing?
    update!(status: :active, started_at: Time.current, answered_by_session: session)
  end

  def end!
    raise InvalidTransition unless active?
    update!(status: :ended, ended_at: Time.current)
  end

  def decline!
    raise InvalidTransition unless ringing?
    update!(status: :declined, ended_at: Time.current)
  end

  def miss!
    raise InvalidTransition unless ringing?
    update!(status: :missed, ended_at: Time.current)
  end

  private

  def caller_and_recipient_are_contacts
    return if Contact.exists?(user_id: caller_id, contact_id: recipient_id)
    errors.add(:recipient, "must be a contact")
  end
end
```

## Dependencies

- 03-invite-accept (need Contact model for validation)
