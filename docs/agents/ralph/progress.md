# Progress Log

## Current State

Feature 04 (contact-list) completed. The codebase now has:
- Full contact list UI with remove functionality
- ContactsController with index and destroy actions
- Mutual contact removal in a transaction
- Turbo confirmation for remove action
- Empty state with invite link

Next: Pick from 05-action-cable-setup, 06-turn-credentials, or 07-call-model. Feature 08 (call-initiation) now has dependencies 04 satisfied; still needs 05 and 07.

---

## Feature Order

| # | Feature | Status | Dependencies |
|---|---------|--------|--------------|
| 01 | user-name | Completed | None |
| 02 | invite-model | Completed | 01 |
| 03 | invite-accept | Completed | 02 |
| 04 | contact-list | Completed | 03 |
| 05 | action-cable-setup | Pending | None |
| 06 | turn-credentials | Pending | None |
| 07 | call-model | Pending | 03 |
| 08 | call-initiation | Pending | 04, 05, 07 |
| 09 | incoming-call-ui | Pending | 05, 07, 08 |
| 10 | webrtc-connection | Pending | 05, 06, 09 |
| 11 | call-hangup | Pending | 10 |
| 12 | multi-device-dismiss | Pending | 09 |
| 13 | call-timeout | Pending | 08, 09 |
| 14 | call-log | Pending | 07 |

---

## Session History

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

Pick `05-action-cable-setup.md` to enable real-time features, `06-turn-credentials.md` for WebRTC infrastructure, or `07-call-model.md` to start on calling data model.
