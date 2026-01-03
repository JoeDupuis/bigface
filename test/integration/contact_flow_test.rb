require "test_helper"

class ContactFlowTest < ActionDispatch::IntegrationTest
  test "full contact flow from empty to having contacts" do
    bob = users(:two)
    sign_in_as(bob)

    get contacts_path
    assert_response :success
    assert_select "p", text: /No contacts yet/

    get new_invite_path
    assert_response :success

    charlie = users(:three)
    Invite.create!(sender: charlie, recipient_email: bob.email_address).accept!(bob)

    get contacts_path
    assert_response :success
    assert_select "li", text: /Charlie/
  end
end
