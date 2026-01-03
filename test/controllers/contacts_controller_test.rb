require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "GET /contacts when logged in with contacts" do
    alice = users(:one)
    sign_in_as(alice)

    get contacts_path

    assert_response :success
    assert_select "li", text: /Charlie/
    assert_select "button", text: "Remove"
  end

  test "GET /contacts with no contacts" do
    bob = users(:two)
    sign_in_as(bob)

    get contacts_path

    assert_response :success
    assert_select "p", text: /No contacts yet/
    assert_select "a[href='#{new_invite_path}']", text: "Invite someone!"
  end

  test "GET /contacts when not logged in redirects to login" do
    get contacts_path

    assert_redirected_to new_session_path
  end

  test "DELETE /contacts/:id removes mutual contacts" do
    alice = users(:one)
    sign_in_as(alice)
    alice_to_charlie = contacts(:alice_to_charlie)

    assert_difference "Contact.count", -2 do
      delete contact_path(alice_to_charlie)
    end

    assert_redirected_to contacts_path
    assert_equal "Contact removed", flash[:notice]
    assert_not Contact.exists?(user: alice, contact: users(:three))
    assert_not Contact.exists?(user: users(:three), contact: alice)
  end

  test "DELETE /contacts/:id for non-owned contact returns 404" do
    bob = users(:two)
    sign_in_as(bob)

    alice = users(:one)
    alice_to_charlie = contacts(:alice_to_charlie)

    assert_no_difference "Contact.count" do
      delete contact_path(alice_to_charlie)
    end

    assert_response :not_found
  end
end
