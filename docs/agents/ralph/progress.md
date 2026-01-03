# Progress Log

## Current State

Feature 07 (call-model) completed. The codebase now has:
- Full Call model with state transitions (answer!, end!, decline!, miss!)
- Status enum: ringing, active, ended, missed, declined
- Validations: caller uniqueness for ringing calls, contacts requirement
- User associations: outgoing_calls, incoming_calls
- Test fixtures: sessions, Dan user, Alice-Bob contacts

Next: Pick 06-turn-credentials (WebRTC infrastructure) or 08-call-initiation (now unblocked). Feature 14 (call-log) is also now unblocked.

---

## Feature Order

| # | Feature | Status | Dependencies |
|---|---------|--------|--------------|
| 01 | user-name | Completed | None |
| 02 | invite-model | Completed | 01 |
| 03 | invite-accept | Completed | 02 |
| 04 | contact-list | Completed | 03 |
| 05 | action-cable-setup | Completed | None |
| 06 | turn-credentials | Pending | None |
| 07 | call-model | Completed | 03 |
| 08 | call-initiation | Pending | 04, 05, 07 |
| 09 | incoming-call-ui | Pending | 05, 07, 08 |
| 10 | webrtc-connection | Pending | 05, 06, 09 |
| 11 | call-hangup | Pending | 10 |
| 12 | multi-device-dismiss | Pending | 09 |
| 13 | call-timeout | Pending | 08, 09 |
| 14 | call-log | Pending | 07 |

---

## Session History

### Session 2026-01-02 (6)

**Feature**: 07-call-model
**Status**: Completed

**What was done**:
- Added InvalidTransition error class to Call model
- Added enum for status (ringing, active, ended, missed, declined)
- Added uniqueness validation for caller_id scoped to ringing status
- Added caller_and_recipient_are_contacts validation
- Added state transition methods: answer!, end!, decline!, miss!
- Added User associations: outgoing_calls, incoming_calls
- Created test/models/call_test.rb with full test coverage
- Created test/fixtures/sessions.yml with alice_session and bob_session
- Updated test/fixtures/contacts.yml with alice_to_bob, bob_to_alice
- Updated test/fixtures/users.yml with Dan (user four)
- Updated existing tests affected by new contact fixtures

**Notes for next session**:
- Feature 08 (call-initiation) is now unblocked (dependencies 04, 05, 07 complete)
- Feature 14 (call-log) is also now unblocked
- Feature 06 (turn-credentials) has no dependencies
- Dan (user four) has no contacts - use for "no contacts" test scenarios

---

### Session 2026-01-02 (5)

**Feature**: 05-action-cable-setup
**Status**: Completed

**What was done**:
- Created ApplicationCable::Channel base class
- Created UserNotificationChannel that streams for current_user
- Created CallChannel with authorization for caller/recipient only
- CallChannel receive method relays messages with `from` field
- Added @rails/actioncable to importmap
- Created JavaScript consumer and user_notification_channel files
- Created Call model migration with full schema (for channel tests)
- Created minimal Call model with belongs_to associations
- Added calls fixture for tests
- Created connection tests (auth, rejection)
- Created channel tests for UserNotification and Call channels

**Notes for next session**:
- Call model exists but is minimal - feature 07 will add validations and state transitions
- Feature 07 (call-model) now has the table but needs full implementation
- Feature 06 (turn-credentials) has no dependencies
- Feature 08 (call-initiation) still needs 07

---

### Session 2026-01-02 (4)

**Feature**: 04-contact-list
**Status**: Completed

**What was done**:
- Added `destroy` action to ContactsController with mutual contact removal
- Added :destroy to contacts routes
- Updated contacts/index.html.erb with full UI (list, remove buttons, empty state)
- Added Charlie (user three) to fixtures for testing
- Added contact fixtures (alice_to_charlie, charlie_to_alice)
- Created controller tests for all spec requirements
- Created integration test for full contact flow

**Notes for next session**:
- Features 05, 06, and 07 are all unblocked
- Feature 08 (call-initiation) needs 05 and 07 to be done first
- Consider doing 05 (action-cable-setup) next to unblock more calling features

---

### Session 2026-01-02 (3)

**Feature**: 03-invite-accept
**Status**: Completed

**What was done**:
- Added `accept!`, `accepted?`, and `pending_for` methods to Invite model
- Added uniqueness validation to Contact model
- Added index, show, update, destroy actions to InvitesController
- Created invites/index.html.erb and invites/show.html.erb views
- Added ContactsController with index action and basic view
- Added contacts route
- Full test coverage for model and controller

**Notes for next session**:
- Feature 04 (contact-list) and 07 (call-model) now have their dependencies satisfied
- Features 05 and 06 have no dependencies
- ContactsController is minimal - feature 04 will expand it

---

### Session 2026-01-02 (2)

**Feature**: 02-invite-model
**Status**: Completed

**What was done**:
- Created Invite model with sender, recipient_email, token, accepted_at, declined_at fields
- Added token generation via `before_create` callback
- Email normalization using Rails `normalizes`
- Uniqueness validation scoped to pending invites (where accepted_at AND declined_at are NULL)
- Custom validations for cannot-invite-self and cannot-invite-existing-contact
- Created Contact model (needed for contact validation, will be fully used in feature 03)
- Created InvitesController with new/create actions
- Created InviteMailer with invite_email action and views
- Added invites routes with token param
- Full test coverage for model, controller, and mailer

**Notes for next session**:
- Feature 03 (invite-accept) depends on 02 and is now unblocked
- Contact model is created but feature 04 (contact-list) depends on 03
- declined_at field was added to support re-invite after decline scenario
- The `pending` scope excludes both accepted and declined invites

---

### Session 2026-01-02

**Feature**: 01-user-name
**Status**: Completed

**What was done**:
- Added `name` field to users table with NOT NULL constraint
- Added presence validation to User model
- Updated fixtures with names (Alice, Bob)
- Updated seeds.rb with two dev users (Developer, Joe)
- Created HomeController and view with "Hello, {name}" greeting
- Added root route to home#show
- Fixed MissionControl::Jobs guards for test environment compatibility

**Notes for next session**:
- Feature 02 (invite-model) depends on 01 and is now unblocked
- Features 05 and 06 have no dependencies and can be done anytime

---

## Suggested Next Feature

Pick `06-turn-credentials.md` for WebRTC infrastructure or `08-call-initiation.md` to start the calling flow. Feature 08 is now fully unblocked.
