# User Name Field

## Description

Add a `name` field to the User model so contacts can be displayed by name rather than just email.

## Behavior

Users have a name that displays throughout the app. The name is required and set during account creation (via seeds for now since registration is disabled).

The home page after login should display "Hello, {name}" as a welcome.

## Models

**User** - add field:
- `name` (string, not null)

Update the existing user fixtures/seeds to include names.

## Tests

### Model Tests

**User validations**
- Given: a user without a name
- When: validating
- Then: validation fails with "Name can't be blank"

**User with name**
- Given: a user with a name
- When: validating
- Then: validation passes

### Controller Tests

**Home page shows name**
- Given: a logged-in user with name "Alice"
- When: visiting the home page
- Then: page displays "Hello, Alice"

## Implementation Notes

- Run `bin/rails generate migration AddNameToUsers name:string`
- Add `null: false` constraint in migration
- Add `validates :name, presence: true` to User model
- Update any user fixtures to include names

### Update seeds.rb

The current seed creates one dev user. Update it to include names and add a second user for testing calls:

```ruby
if Rails.env.development?
  User.find_or_create_by!(email_address: "dev@example.com") do |user|
    user.name = "Developer"
    user.password = "Xk9#mP7$qR2@vL5"
    user.admin = true
  end

  User.find_or_create_by!(email_address: "joe@example.com") do |user|
    user.name = "Joe"
    user.password = "Xk9#mP7$qR2@vL5"
  end
end
```

This gives two users to test the contact/calling flow in development.

## Dependencies

None - this is a foundational feature.
