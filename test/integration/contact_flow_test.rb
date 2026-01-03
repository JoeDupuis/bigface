require "test_helper"

class ContactFlowTest < ActionDispatch::IntegrationTest
  test "full contact flow from empty to having contacts" do
    dan = users(:four)
    sign_in_as(dan)

    get contacts_path
    assert_response :success
    assert_select "p", text: /No contacts yet/

    get new_invite_path
    assert_response :success

    bob = users(:two)
    Invite.create!(sender: bob, recipient_email: dan.email_address).accept!(dan)

    get contacts_path
    assert_response :success
    assert_select "li", text: /Bob/
  end
end
