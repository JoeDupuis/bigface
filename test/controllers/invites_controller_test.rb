require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "GET /invites/new shows invite form" do
    get new_invite_path

    assert_response :success
    assert_select "input[name='invite[recipient_email]']"
  end

  test "POST /invites with valid email creates invite and enqueues email" do
    assert_difference "Invite.count", 1 do
      assert_enqueued_emails 1 do
        post invites_path, params: { invite: { recipient_email: "friend@example.com" } }
      end
    end

    assert_redirected_to root_path
    assert_equal "Invite sent to friend@example.com", flash[:notice]
  end

  test "POST /invites with existing user email shows same response" do
    existing_user = users(:two)

    assert_difference "Invite.count", 1 do
      assert_enqueued_emails 1 do
        post invites_path, params: { invite: { recipient_email: existing_user.email_address } }
      end
    end

    assert_redirected_to root_path
    assert_equal "Invite sent to #{existing_user.email_address}", flash[:notice]
  end

  test "POST /invites with own email does not create invite" do
    assert_no_difference "Invite.count" do
      post invites_path, params: { invite: { recipient_email: @user.email_address } }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='invite[recipient_email]']"
  end

  test "POST /invites with already-contact email does not create invite" do
    bob = users(:two)
    Contact.create!(user: @user, contact: bob)
    Contact.create!(user: bob, contact: @user)

    assert_no_difference "Invite.count" do
      post invites_path, params: { invite: { recipient_email: bob.email_address } }
    end

    assert_response :unprocessable_entity
  end

  test "GET /invites when logged in shows pending invites for current user" do
    bob = users(:two)
    sign_in_as(bob)
    alice = users(:one)
    invite_to_bob = Invite.create!(sender: alice, recipient_email: bob.email_address)
    Invite.create!(sender: bob, recipient_email: "other@example.com")

    get invites_path

    assert_response :success
    assert_select "p", text: /Alice/
  end

  test "GET /invites with no pending invites" do
    get invites_path

    assert_response :success
    assert_select "p", text: /No pending invites/
  end

  test "GET /invites when not logged in redirects to login" do
    sign_out

    get invites_path

    assert_redirected_to new_session_path
  end

  test "GET /invites/:token when not logged in redirects to login" do
    invite = invites(:alice_to_carol)
    sign_out

    get invite_path(invite.token)

    assert_redirected_to new_session_path
  end

  test "GET /invites/:token when logged in as wrong user returns 404" do
    alice = users(:one)
    bob = users(:two)
    invite = Invite.create!(sender: alice, recipient_email: bob.email_address)
    sign_in_as(alice)

    get invite_path(invite.token)

    assert_response :not_found
  end

  test "GET /invites/:token when logged in as correct user" do
    alice = users(:one)
    bob = users(:two)
    invite = Invite.create!(sender: alice, recipient_email: bob.email_address)
    sign_in_as(bob)

    get invite_path(invite.token)

    assert_response :success
    assert_select "p", text: /Alice wants to connect with you/
    assert_select "input[type='submit'][value='Accept']"
    assert_select "input[type='submit'][value='Decline']"
  end

  test "PATCH /invites/:token accepts invite" do
    alice = users(:one)
    bob = users(:two)
    invite = Invite.create!(sender: alice, recipient_email: bob.email_address)
    sign_in_as(bob)

    assert_difference "Contact.count", 2 do
      patch invite_path(invite.token)
    end

    invite.reload
    assert invite.accepted_at.present?
    assert_redirected_to contacts_path
    assert_equal "You are now connected with Alice!", flash[:notice]
  end

  test "PATCH /invites/:token for already accepted invite" do
    alice = users(:one)
    bob = users(:two)
    invite = Invite.create!(sender: alice, recipient_email: bob.email_address)
    invite.accept!(bob)
    sign_in_as(bob)

    assert_no_difference "Contact.count" do
      patch invite_path(invite.token)
    end

    assert_redirected_to contacts_path
    assert_equal "Already accepted", flash[:notice]
  end

  test "PATCH /invites/:token as wrong user returns 404" do
    alice = users(:one)
    bob = users(:two)
    invite = Invite.create!(sender: alice, recipient_email: bob.email_address)
    sign_in_as(alice)

    patch invite_path(invite.token)

    assert_response :not_found
  end

  test "DELETE /invites/:token declines invite" do
    alice = users(:one)
    bob = users(:two)
    invite = Invite.create!(sender: alice, recipient_email: bob.email_address)
    sign_in_as(bob)

    assert_difference "Invite.count", -1 do
      delete invite_path(invite.token)
    end

    assert_redirected_to invites_path
    assert_equal "Invite declined", flash[:notice]
  end

  test "DELETE /invites/:token as wrong user returns 404" do
    alice = users(:one)
    bob = users(:two)
    invite = Invite.create!(sender: alice, recipient_email: bob.email_address)
    sign_in_as(alice)

    delete invite_path(invite.token)

    assert_response :not_found
  end

  test "GET /invites/:invalid_token returns 404" do
    bob = users(:two)
    sign_in_as(bob)

    get invite_path("invalid_token")

    assert_response :not_found
  end
end
