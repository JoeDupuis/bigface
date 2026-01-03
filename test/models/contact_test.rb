require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "belongs to user and contact" do
    contact = contacts(:alice_to_bob)

    assert_equal users(:one), contact.user
    assert_equal users(:two), contact.contact
  end

  test "uniqueness validation" do
    alice = users(:one)
    bob = users(:two)

    duplicate = Contact.new(user: alice, contact: bob)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
