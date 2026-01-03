require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "validates name presence" do
    user = users(:one)
    user.name = nil

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "user with name is valid" do
    user = users(:one)

    assert user.valid?
  end
end
