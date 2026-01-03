# Accept or Decline Invites

## Description

Users can view pending invites sent to their email and accept or decline them. Accepting creates mutual contacts. Declining removes the invite.

## Behavior

### Viewing Pending Invites

- `GET /invites` shows invites where `recipient_email` matches current user's email
- Only shows pending invites (not accepted or declined)
- Each invite shows sender's name and accept/decline buttons

### Viewing Specific Invite (from email link)

- `GET /invites/:token` shows the invite details
- If logged in as correct recipient: shows accept/decline buttons
- If not logged in: redirects to login, then back

### Accepting an Invite

- `PATCH /invites/:token` with accept action
- Creates Contact records for both users (mutual)
- Sets `accepted_at` on the invite
- Redirects to contacts with success message

### Declining an Invite

- `DELETE /invites/:token`
- Destroys the invite record
- Redirects to invites index (or contacts)

## Routes

```ruby
resources :invites, only: [:index, :new, :create, :show, :update, :destroy], param: :token
```

This feature implements: `index`, `show`, `update`, `destroy`
Feature 02 implements: `new`, `create`

## Tests

### Model Tests

**Invite#accept! creates contacts**
- Given: invite from Alice to Bob (both users exist)
- When: calling invite.accept!(bob)
- Then: Contact created for Alice → Bob
- And: Contact created for Bob → Alice
- And: invite.accepted_at is set

**Invite#accepted? returns true when accepted**
- Given: invite with accepted_at set
- When: calling invite.accepted?
- Then: returns true

**Invite#accepted? returns false when pending**
- Given: invite with accepted_at nil
- When: calling invite.accepted?
- Then: returns false

**Invite.pending_for(user) returns matching invites**
- Given: invite to bob@example.com (pending)
- And: invite to alice@example.com (pending)
- And: invite to bob@example.com (already accepted)
- When: calling Invite.pending_for(bob)
- Then: returns only the pending invite to bob

### Contact Model Tests

**Contact belongs to user and contact**
- Given: a valid contact
- When: checking associations
- Then: user and contact are present

**Contact uniqueness**
- Given: existing contact from user A to user B
- When: creating duplicate contact A → B
- Then: validation fails

### Controller Tests

**GET /invites when logged in**
- Given: logged-in user Bob with email bob@example.com
- And: pending invite from Alice to bob@example.com
- And: pending invite from Charlie to charlie@example.com
- When: visiting /invites
- Then: shows invite from Alice
- And: does not show invite to Charlie

**GET /invites with no pending invites**
- Given: logged-in user with no pending invites
- When: visiting /invites
- Then: shows "No pending invites"

**GET /invites when not logged in**
- Given: not logged in
- When: visiting /invites
- Then: redirects to login

**GET /invites/:token when not logged in**
- Given: valid invite token
- When: visiting show page while logged out
- Then: redirects to login
- And: after login, returns to show page

**GET /invites/:token when logged in as wrong user**
- Given: invite to bob@example.com
- And: logged in as alice@example.com
- When: visiting show page
- Then: returns 404

**GET /invites/:token when logged in as correct user**
- Given: invite from Alice to bob@example.com
- And: logged in as bob@example.com
- When: visiting show page
- Then: shows "Alice wants to connect with you"
- And: shows Accept and Decline buttons

**PATCH /invites/:token accepts invite**
- Given: invite from Alice to Bob
- And: logged in as Bob
- When: patching /invites/:token
- Then: creates mutual contacts
- And: sets accepted_at
- And: redirects to contacts path
- And: shows success flash

**PATCH /invites/:token for already accepted invite**
- Given: already-accepted invite
- And: logged in as recipient
- When: patching
- Then: redirects to contacts
- And: shows "Already accepted" notice

**PATCH /invites/:token as wrong user**
- Given: invite to bob@example.com
- And: logged in as alice@example.com
- When: patching
- Then: returns 404

**DELETE /invites/:token declines invite**
- Given: pending invite from Alice to Bob
- And: logged in as Bob
- When: deleting /invites/:token
- Then: destroys the invite
- And: redirects to invites path
- And: shows "Invite declined" notice

**DELETE /invites/:token as wrong user**
- Given: invite to bob@example.com
- And: logged in as alice@example.com
- When: deleting
- Then: returns 404

**GET /invites/:invalid_token**
- Given: invalid token
- When: visiting show page
- Then: returns 404

## Implementation Notes

- Create Contact model with migration
- Add index, show, update, destroy actions to InvitesController
- Add `accept!` method to Invite model
- Add `accepted?` predicate to Invite
- Add `Invite.pending_for(user)` scope
- Store return URL in session before login redirect

```ruby
class InvitesController < ApplicationController
  before_action :set_invite, only: [:show, :update, :destroy]

  def index
    @invites = Invite.pending_for(current_user)
  end

  def show
  end

  def update
    if @invite.accepted?
      redirect_to contacts_path, notice: "Already accepted"
    else
      @invite.accept!(current_user)
      redirect_to contacts_path, notice: "You are now connected with #{@invite.sender.name}!"
    end
  end

  def destroy
    @invite.destroy!
    redirect_to invites_path, notice: "Invite declined"
  end

  private

  def set_invite
    @invite = Invite.find_by!(token: params[:token])
    authorize_recipient!
  end

  def authorize_recipient!
    unless @invite.recipient_email == current_user.email_address
      raise ActiveRecord::RecordNotFound
    end
  end
end
```

```ruby
class Invite < ApplicationRecord
  scope :pending, -> { where(accepted_at: nil) }

  def self.pending_for(user)
    pending.where(recipient_email: user.email_address)
  end

  def accept!(user)
    transaction do
      update!(accepted_at: Time.current)
      Contact.create!(user: sender, contact: user)
      Contact.create!(user: user, contact: sender)
    end
  end

  def accepted?
    accepted_at.present?
  end
end
```

## Dependencies

- 02-invite-model (need Invite to exist)
