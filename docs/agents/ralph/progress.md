# Progress Log

## Current State

Feature 01 (user-name) completed. The codebase now has:
- User model with name field and validation
- Home page displaying "Hello, {name}" greeting
- Two dev users in seeds (Developer, Joe)

Next: Pick from 02-invite-model, 05-action-cable-setup, or 06-turn-credentials.

---

## Feature Order

| # | Feature | Status | Dependencies |
|---|---------|--------|--------------|
| 01 | user-name | Completed | None |
| 02 | invite-model | Pending | 01 |
| 03 | invite-accept | Pending | 02 |
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

Pick `02-invite-model.md` to continue the invite/contact flow, or do `05-action-cable-setup.md` or `06-turn-credentials.md` which have no dependencies.
