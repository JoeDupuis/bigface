# Progress Log

## Current State

Feature 06 (turn-credentials) completed. The codebase now has:
- TurnCredentials model (plain Ruby class) that fetches TURN/STUN credentials from Cloudflare
- GET /turn_credentials endpoint returning formatted ICE servers JSON
- Caching with 1-hour expiration (credentials valid for 24h)
- Added webmock gem for HTTP stubbing in tests

Next: Pick 10-webrtc-connection (now unblocked), 14-call-log, or 11-call-hangup (needs 10).

---

## Previous State

Feature 13 (call-timeout) completed. The codebase now has:
- CallTimeoutJob scheduled on call creation (2s in test, 30s in production)
- Call#timeout! marks call as missed and broadcasts to both channels
- call_controller.js subscribes to CallChannel, shows "No answer" on timeout
- incoming_call_controller.js handles call-timeout event to dismiss overlay

Next: Pick 06-turn-credentials (unblocks 10), 14-call-log, or 10-webrtc-connection (needs 06). Feature 11 (call-hangup) needs 10.

---

## Feature Order

| # | Feature | Status | Dependencies |
|---|---------|--------|--------------|
| 01 | user-name | Completed | None |
| 02 | invite-model | Completed | 01 |
| 03 | invite-accept | Completed | 02 |
| 04 | contact-list | Completed | 03 |
| 05 | action-cable-setup | Completed | None |
| 06 | turn-credentials | Completed | None |
| 07 | call-model | Completed | 03 |
| 08 | call-initiation | Completed | 04, 05, 07 |
| 09 | incoming-call-ui | Completed | 05, 07, 08 |
| 10 | webrtc-connection | Pending | 05, 06, 09 |
| 11 | call-hangup | Pending | 10 |
| 12 | multi-device-dismiss | Completed | 09 |
| 13 | call-timeout | Completed | 08, 09 |
| 14 | call-log | Pending | 07 |

---

## Session History

### Session 2026-01-02 (11)

**Feature**: 06-turn-credentials
**Status**: Completed

**What was done**:
- Created TurnCredentials model (plain Ruby class in app/models)
- Added TurnCredentialsController with show action
- Added GET /turn_credentials route
- Fetches TURN/STUN credentials from Cloudflare API
- Caches credentials for 1 hour (valid for 24h)
- Returns 401 for unauthenticated requests
- Returns 503 on Cloudflare API errors
- Added webmock gem for HTTP stubbing in tests
- Added WebMock.disable_net_connect!(allow_localhost: true) for system tests
- Fixed pre-existing CallsControllerTest broadcast test failures with with_test_cable_adapter helper

**Notes for next session**:
- Feature 10 (webrtc-connection) is now unblocked (dependencies 05, 06, 09 complete)
- Feature 14 (call-log) is available
- Feature 11 (call-hangup) needs 10 first

---

### Session 2026-01-02 (10)

**Feature**: 13-call-timeout
**Status**: Completed

**What was done**:
- Created CallTimeoutJob scheduled via after_create_commit callback
- Added RING_TIMEOUT constant (2 seconds in test, 30 seconds in production)
- Added Call#timeout! method that marks call as missed and broadcasts
- Added broadcast_timeout to broadcast to CallChannel and UserNotificationChannel
- Updated call_controller.js to subscribe to CallChannel and handle timeout
- Updated incoming_call_controller.js to handle call-timeout event
- Updated user_notification_channel.js to dispatch call-timeout event
- Added status target to calls/show.html.erb for "No answer" message
- Created test/jobs/call_timeout_job_test.rb with 5 tests
- Added 6 tests to test/models/call_test.rb for timeout functionality

**Notes for next session**:
- Feature 14 (call-log) is available (dependency 07 satisfied)
- Feature 06 (turn-credentials) has no dependencies, unblocks 10
- Feature 10 (webrtc-connection) needs 06 first
- Feature 11 (call-hangup) needs 10

---

### Session 2026-01-02 (9)

**Feature**: 12-multi-device-dismiss
**Status**: Completed

**What was done**:
- Added broadcast to UserNotificationChannel in Call#broadcast_answered
- Updated user_notification_channel.js to dispatch call-answered event
- Updated incoming_call_controller.js to handle call-answered and dismiss overlay
- Added model test for broadcast to UserNotificationChannel
- Added system test using Capybara's using_session for multi-device scenario
- Fixed importmap: @rails/actioncable to use actioncable.esm.js
- Fixed channel import to use "channels/consumer" instead of relative "./consumer"
- Made CSRF token handling robust with optional chaining
- Changed cable.yml test adapter to async for system tests
- Added Cuprite require to application_system_test_case
- Enhanced SessionTestHelper to support Cuprite driver

**Notes for next session**:
- Features 13 (call-timeout) and 14 (call-log) are available
- Feature 10 (webrtc-connection) needs 06 (turn-credentials) first

---

### Session 2026-01-02 (8)

**Feature**: 09-incoming-call-ui
**Status**: Completed

**What was done**:
- Created Call::AnswersController with create action (RESTful)
- Created Call::DeclinesController with create action (RESTful)
- Added nested routes: POST /calls/:call_id/answer and /decline
- Added broadcast_answered and broadcast_declined to Call model
- Created incoming_call Stimulus controller
- Created incoming-call-overlay CSS component (RSCSS)
- Added incoming call UI to application layout
- Updated SessionTestHelper to accept optional session parameter
- Full test coverage for answer/decline actions and broadcasts

**Notes for next session**:
- Features 12 (multi-device-dismiss) and 13 (call-timeout) are now unblocked
- Feature 10 (webrtc-connection) needs 06 (turn-credentials) first
- Feature 14 (call-log) is also available

---

### Session 2026-01-02 (7)

**Feature**: 08-call-initiation
**Status**: Completed

**What was done**:
- Created CallsController with create and show actions
- Added after_create_commit callback to Call model for broadcasting
- Created calls/show.html.erb with Stimulus controller data attributes
- Added Call button to contacts/index.html.erb
- Created Stimulus call_controller.js for video preview
- Added calls routes (create, show)
- Created controller tests for all spec requirements
- Created integration test for start call flow

**Notes for next session**:
- Feature 09 (incoming-call-ui) is now unblocked (dependencies 05, 07, 08 complete)
- Feature 12 (multi-device-dismiss) and 13 (call-timeout) depend on 09
- Feature 06 (turn-credentials) still has no dependencies
- Existing fixture alice_calls_bob is ringing, use Bob as caller in tests to avoid conflict

---

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

Pick `10-webrtc-connection.md` (now unblocked), `14-call-log.md`, or proceed with `11-call-hangup.md` after 10 is done.
