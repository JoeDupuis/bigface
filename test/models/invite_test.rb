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

    invite = Invite.new(
      sender: alice,
      recipient_email: bob.email_address
    )

    assert_not invite.valid?
    assert_includes invite.errors[:recipient_email], "already a contact"
  end

  test "accept! creates contacts" do
    bob = users(:two)
    charlie = users(:three)
    invite = Invite.create!(sender: bob, recipient_email: charlie.email_address)

    invite.accept!(charlie)

    assert Contact.exists?(user: bob, contact: charlie)
    assert Contact.exists?(user: charlie, contact: bob)
    assert invite.accepted_at.present?
  end

  test "accepted? returns true when accepted" do
    bob = users(:two)
    charlie = users(:three)
    invite = Invite.create!(sender: bob, recipient_email: charlie.email_address)
    invite.update!(accepted_at: Time.current)

    assert invite.accepted?
  end

  test "accepted? returns false when pending" do
    invite = invites(:alice_to_carol)

    assert_not invite.accepted?
  end

  test "pending_for returns matching invites" do
    bob = users(:two)
    charlie = users(:three)
    pending_to_charlie = Invite.create!(sender: bob, recipient_email: charlie.email_address)
    Invite.create!(sender: charlie, recipient_email: bob.email_address)
    accepted_to_charlie = Invite.create!(sender: bob, recipient_email: "temp@example.com")
    accepted_to_charlie.update!(accepted_at: Time.current)
    accepted_to_charlie.update_column(:recipient_email, charlie.email_address)

    result = Invite.pending_for(charlie)

    assert_includes result, pending_to_charlie
    assert_not_includes result, accepted_to_charlie
  end
end
