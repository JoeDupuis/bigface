# Progress Log

## Current State

Project not yet started. The existing codebase has:
- User model with email/password authentication
- Session model for login sessions
- Basic authentication controllers

Begin with `01-user-name.md` to add the name field to users.

---

## Feature Order

| # | Feature | Status | Dependencies |
|---|---------|--------|--------------|
| 01 | user-name | Pending | None |
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

_No sessions yet._

---

## Suggested Next Feature

Start with `01-user-name.md` - it adds the name field to User, which is foundational for displaying contact names throughout the app.

After that, features 05 (Action Cable) and 06 (TURN credentials) have no dependencies and can be done early to parallelize work.
