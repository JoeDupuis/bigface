require "test_helper"

class UserNotificationChannelTest < ActionCable::Channel::TestCase
  test "subscribes for current user" do
    user = users(:one)
    stub_connection current_user: user

    subscribe

    assert subscription.confirmed?
    assert_has_stream_for user
  end

  test "rejects unauthenticated connection" do
    stub_connection current_user: nil

    subscribe

    assert subscription.rejected?
  end
end
