# Progress Log

## Current State

Feature 03 (invite-accept) completed. The codebase now has:
- Full invite flow: send, view, accept, decline
- Invite model with accept!, accepted?, pending_for methods
- Contact model with uniqueness validation
- InvitesController with all actions (index, show, new, create, update, destroy)
- ContactsController with index action (basic, will be expanded in feature 04)
- Views for invites index and show

Next: Pick from 04-contact-list, 05-action-cable-setup, 06-turn-credentials, or 07-call-model.

---

## Feature Order

| # | Feature | Status | Dependencies |
|---|---------|--------|--------------|
| 01 | user-name | Completed | None |
| 02 | invite-model | Completed | 01 |
| 03 | invite-accept | Completed | 02 |
| 04 | contact-list | Pending | 03 |
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

Pick `04-contact-list.md` to continue the invite flow, `07-call-model.md` to start on calling features, or do `05-action-cable-setup.md` or `06-turn-credentials.md` which have no dependencies.
