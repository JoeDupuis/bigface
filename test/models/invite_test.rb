require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "requires sender" do
    invite = Invite.new(recipient_email: "test@example.com")

    assert_not invite.valid?
    assert_includes invite.errors[:sender], "must exist"
  end

  test "requires recipient_email" do
    invite = Invite.new(sender: users(:one))

    assert_not invite.valid?
    assert_includes invite.errors[:recipient_email], "can't be blank"
  end

  test "normalizes email" do
    invite = Invite.new(
      sender: users(:one),
      recipient_email: "  FOO@BAR.com  "
    )

    assert_equal "foo@bar.com", invite.recipient_email
  end

  test "generates token on create" do
    invite = Invite.create!(
      sender: users(:one),
      recipient_email: "unique@example.com"
    )

    assert invite.token.present?
    assert_equal 43, invite.token.length
  end

  test "cannot invite self" do
    user = users(:one)
    invite = Invite.new(
      sender: user,
      recipient_email: user.email_address
    )

    assert_not invite.valid?
    assert_includes invite.errors[:recipient_email], "can't invite yourself"
  end

  test "cannot duplicate pending invite" do
    existing = invites(:alice_to_carol)
    invite = Invite.new(
      sender: existing.sender,
      recipient_email: existing.recipient_email
    )

    assert_not invite.valid?
    assert_includes invite.errors[:recipient_email], "has already been taken"
  end

  test "can re-invite after previous was declined" do
    declined = invites(:declined)
    invite = Invite.new(
      sender: declined.sender,
      recipient_email: declined.recipient_email
    )

    assert invite.valid?
  end

  test "cannot invite existing contact" do
    alice = users(:one)
    bob = users(:two)
    Contact.create!(user: alice, contact: bob)
    Contact.create!(user: bob, contact: alice)

    invite = Invite.new(
      sender: alice,
      recipient_email: bob.email_address
    )

    assert_not invite.valid?
    assert_includes invite.errors[:recipient_email], "already a contact"
  end
end
