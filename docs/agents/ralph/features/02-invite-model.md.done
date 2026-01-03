# Invite Model and Sending

## Description

Users can invite others to become contacts by entering an email address. The system sends an email with a link to accept.

## Behavior

### Sending an Invite

1. User navigates to invite form
2. Enters an email address
3. System creates an Invite record with a unique token
4. System sends an email with the accept link
5. User sees generic confirmation (same message regardless of whether email exists)

### Privacy: No User Enumeration

The response must be identical whether the recipient email belongs to an existing user or not. This prevents attackers from discovering which emails are registered.

- Always show: "Invite sent to {email}"
- Never reveal: "User already exists" or "User not found"
- The invite is created and email sent regardless

### Invite Rules

- Cannot invite yourself
- Cannot invite someone you're already contacts with
- Cannot send duplicate pending invites (same sender + email combo)
- Email is normalized (stripped, downcased) before saving

## Models

**Invite**
- `sender_id` - FK to User (who sent it)
- `recipient_email` - string, not null, normalized
- `token` - string, unique, generated on create
- `accepted_at` - datetime, null until accepted

See `docs/agents/data-model.md` for full schema.

## Routes

```ruby
resources :invites, only: [:index, :new, :create, :show, :update, :destroy], param: :token
```

This feature implements: `new`, `create`
Feature 03 implements: `index`, `show`, `update`, `destroy`

## Tests

### Model Tests

**Invite requires sender**
- Given: an invite without sender
- When: validating
- Then: fails with "Sender must exist"

**Invite requires recipient_email**
- Given: an invite without recipient_email
- When: validating
- Then: fails with "Recipient email can't be blank"

**Invite normalizes email**
- Given: an invite with recipient_email "  FOO@BAR.com  "
- When: saving
- Then: recipient_email is "foo@bar.com"

**Invite generates token on create**
- Given: a new valid invite
- When: saving
- Then: token is present and unique

**Cannot invite self**
- Given: user with email "me@example.com"
- When: creating invite with recipient_email "me@example.com"
- Then: validation fails with "Can't invite yourself"

**Cannot duplicate pending invite**
- Given: existing pending invite from user A to "bob@example.com"
- When: user A creates another invite to "bob@example.com"
- Then: validation fails with uniqueness error

**Can re-invite after previous was declined**
- Given: declined invite from user A to "bob@example.com"
- When: user A creates new invite to "bob@example.com"
- Then: invite is created successfully

### Controller Tests

**GET /invites/new**
- Given: logged-in user
- When: visiting /invites/new
- Then: shows invite form with email field

**POST /invites with valid email**
- Given: logged-in user
- When: posting to /invites with recipient_email "friend@example.com"
- Then: creates Invite record
- And: enqueues email delivery
- And: redirects with notice "Invite sent to friend@example.com"

**POST /invites with existing user email (no enumeration)**
- Given: logged-in user
- And: existing user with email "existing@example.com"
- When: posting to /invites with recipient_email "existing@example.com"
- Then: creates Invite record
- And: enqueues email delivery
- And: redirects with notice "Invite sent to existing@example.com"
- (Same response as non-existing email)

**POST /invites with own email**
- Given: logged-in user with email "me@example.com"
- When: posting to /invites with recipient_email "me@example.com"
- Then: does not create Invite
- And: re-renders form with error

**POST /invites with already-contact email**
- Given: logged-in user Alice
- And: Alice already has Bob as a contact
- When: posting to /invites with Bob's email
- Then: does not create Invite
- And: re-renders form with error "Already a contact"

### Mailer Tests

**Invite email**
- Given: an invite from Alice to bob@example.com
- When: delivering InviteMailer.invite_email(invite)
- Then: email sent to bob@example.com
- And: subject includes "Alice" and invitation context
- And: body contains accept link with token

## Implementation Notes

- Create Invite model with migration
- Use `before_create` callback to generate token: `SecureRandom.urlsafe_base64(32)`
- Create InvitesController with new/create actions (other actions in feature 03)
- Create InviteMailer with invite_email action
- The accept URL will be: `/invites/:token` (show page has accept button)
- Use `normalizes :recipient_email, with: ->(e) { e.strip.downcase }`

```ruby
class InvitesController < ApplicationController
  def new
    @invite = Invite.new
  end

  def create
    @invite = current_user.sent_invites.build(invite_params)
    if @invite.save
      InviteMailer.invite_email(@invite).deliver_later
      redirect_to contacts_path, notice: "Invite sent to #{@invite.recipient_email}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def invite_params
    params.require(:invite).permit(:recipient_email)
  end
end
```

## Dependencies

- 01-user-name (need sender's name for email)
