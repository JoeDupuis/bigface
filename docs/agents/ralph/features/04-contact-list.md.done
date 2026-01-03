# Contact List UI

## Description

Users see their contacts on a dedicated page. This is the main interface - they click a contact's name to call them. They can also remove contacts.

## Behavior

### Contact List Page

- Shows all contacts as a simple list
- Each contact shows their name
- Each contact is clickable (calls them - implemented in later feature)
- "Remove" link/button to delete the contact relationship
- Link to invite new contacts
- If no contacts, show "No contacts yet. Invite someone!"

### Removing Contacts

- Removes both Contact records (mutual)
- Shows confirmation before removing
- Redirects back to contact list with notice

## Routes

```ruby
resources :contacts, only: [:index, :destroy]
```

## Tests

### Controller Tests

**GET /contacts when logged in**
- Given: logged-in user with 2 contacts (Alice, Bob)
- When: visiting /contacts
- Then: shows Alice and Bob's names
- And: shows remove link for each

**GET /contacts with no contacts**
- Given: logged-in user with no contacts
- When: visiting /contacts
- Then: shows "No contacts yet"
- And: shows link to invite

**GET /contacts when not logged in**
- Given: not logged in
- When: visiting /contacts
- Then: redirects to login

**DELETE /contacts/:id removes mutual contacts**
- Given: logged-in user Alice with contact Bob
- When: deleting the contact
- Then: Alice's contact to Bob is removed
- And: Bob's contact to Alice is removed
- And: redirects to /contacts
- And: shows success notice

**DELETE /contacts/:id for non-owned contact**
- Given: logged-in user Alice
- And: contact between Bob and Charlie (Alice not involved)
- When: Alice tries to delete that contact
- Then: returns 404 or forbidden

### Integration Tests

**Full contact flow**
1. User visits /contacts
2. Sees "No contacts yet"
3. Clicks "Invite someone"
4. Arrives at /invites/new
5. (invite acceptance happens)
6. User revisits /contacts
7. Sees the new contact's name

## Implementation Notes

- ContactsController with index and destroy
- `destroy` action should delete both directions in a transaction
- Find contacts via `current_user.contacts` association
- The contact list is the main landing page after login

## View Structure

```erb
# app/views/contacts/index.html.erb
<h1>Your Contacts</h1>

<% if @contacts.any? %>
  <ul>
    <% @contacts.each do |contact| %>
      <li>
        <%= contact.contact.name %>
        <%= button_to "Remove", contact, method: :delete,
            data: { turbo_confirm: "Remove #{contact.contact.name}?" } %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No contacts yet. <%= link_to "Invite someone!", new_invite_path %></p>
<% end %>

<%= link_to "Invite a contact", new_invite_path %>
```

## Dependencies

- 03-invite-accept (need Contact model to exist)
