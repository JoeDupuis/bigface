require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "belongs to user and contact" do
    alice = users(:one)
    bob = users(:two)
    contact = Contact.create!(user: alice, contact: bob)

    assert_equal alice, contact.user
    assert_equal bob, contact.contact
  end

  test "uniqueness validation" do
    alice = users(:one)
    bob = users(:two)
    Contact.create!(user: alice, contact: bob)

    duplicate = Contact.new(user: alice, contact: bob)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
