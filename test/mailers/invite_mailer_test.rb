require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "invite_email" do
    invite = invites(:alice_to_carol)
    email = InviteMailer.invite_email(invite)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ invite.recipient_email ], email.to
    assert_includes email.subject, invite.sender.name
    assert_includes email.subject, "invited"

    assert_includes email.body.encoded, invite.sender.name
    assert_includes email.body.encoded, invite.token
  end
end
