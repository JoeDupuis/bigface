# Data Model

## Overview

BigFace is a video calling app designed for simplicity. Users have contacts they can call with one click. Calls ring on all logged-in devices, and the first to answer wins.

## Models

### User (extend existing)

The existing User model needs a `name` field for display purposes.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK | |
| email_address | string | unique, not null | Existing |
| password_digest | string | not null | Existing |
| admin | boolean | default: false | Existing |
| name | string | not null | Display name |
| created_at | datetime | | |
| updated_at | datetime | | |

### Invite

Pending invitations to become contacts. When accepted, creates mutual Contact records.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK | |
| sender_id | integer | FK → users, not null | Who sent the invite |
| recipient_email | string | not null | Invitee's email (normalized) |
| token | string | unique, not null | For accept link |
| accepted_at | datetime | nullable | Null = pending |
| created_at | datetime | | |
| updated_at | datetime | | |

**Indexes:**
- `[sender_id, recipient_email]` unique (no duplicate invites)
- `token` unique

**Notes:**
- Token is generated on create (SecureRandom.urlsafe_base64)
- When accepted: set accepted_at, create Contact records for both directions
- Cannot invite yourself
- Cannot invite someone you're already contacts with

### Contact

Represents the contact list relationship. Always bidirectional (both users get a Contact record).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK | |
| user_id | integer | FK → users, not null | The user whose list this is |
| contact_id | integer | FK → users, not null | The contact in their list |
| created_at | datetime | | |
| updated_at | datetime | | |

**Indexes:**
- `[user_id, contact_id]` unique

**Notes:**
- When invite is accepted, create TWO records: A→B and B→A
- This allows each user to have their own contact list
- Query: `user.contacts` returns all users in their contact list

### Call

A call attempt between two users. Tracks state from ringing through completion.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK | |
| caller_id | integer | FK → users, not null | Who initiated |
| recipient_id | integer | FK → users, not null | Who was called |
| status | string | not null, default: 'ringing' | See statuses below |
| started_at | datetime | nullable | When answered |
| ended_at | datetime | nullable | When call ended |
| answered_by_session_id | integer | FK → sessions, nullable | Which device answered |
| created_at | datetime | | |
| updated_at | datetime | | |

**Statuses:**
- `ringing` - Initial state, recipient's devices are ringing
- `active` - Call in progress (answered)
- `ended` - Call completed normally
- `missed` - Timeout, nobody answered
- `declined` - Recipient explicitly declined

**Indexes:**
- `caller_id`
- `recipient_id`
- `status` (for finding active calls)

**Notes:**
- Only one active/ringing call per caller at a time
- Timeout duration: 30 seconds → status changes to missed
- WebRTC signaling (SDP, ICE) happens via Action Cable, not stored

## Associations

```
User
├── has_many :sessions (existing)
├── has_many :contacts
├── has_many :contact_users, through: :contacts, source: :contact
├── has_many :sent_invites, class_name: 'Invite', foreign_key: :sender_id
├── has_many :outgoing_calls, class_name: 'Call', foreign_key: :caller_id
└── has_many :incoming_calls, class_name: 'Call', foreign_key: :recipient_id

Session (existing)
├── belongs_to :user
└── has_many :answered_calls, class_name: 'Call', foreign_key: :answered_by_session_id

Invite
├── belongs_to :sender, class_name: 'User'
└── (recipient is by email, not FK until accepted)

Contact
├── belongs_to :user
└── belongs_to :contact, class_name: 'User'

Call
├── belongs_to :caller, class_name: 'User'
├── belongs_to :recipient, class_name: 'User'
└── belongs_to :answered_by_session, class_name: 'Session', optional: true
```

## Real-time Components

### Action Cable Channels

**CallChannel** - Per-call signaling channel
- Subscribed by caller and all recipient sessions
- Used for: SDP offers/answers, ICE candidates, call state changes
- Broadcast events: `ring`, `answer`, `ice_candidate`, `hangup`, `declined`

**UserNotificationChannel** - Per-user notification channel
- Subscribed by all user sessions
- Used for: incoming call alerts, call state updates
- When a call starts ringing, broadcasts to recipient's channel
- All logged-in devices receive the ring notification

## Cloudflare TURN/STUN

WebRTC connections use Cloudflare's TURN service. Credentials are fetched via their API.

**Required ENV vars:**
- `CLOUDFLARE_TURN_TOKEN_ID`
- `CLOUDFLARE_TURN_API_TOKEN`

**TURN credential flow:**
1. Client requests TURN credentials from Rails API
2. Rails fetches short-lived credentials from Cloudflare
3. Client uses credentials for WebRTC peer connection
