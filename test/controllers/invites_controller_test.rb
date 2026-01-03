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
end
