require "test_helper"

class CallChannelTest < ActionCable::Channel::TestCase
  test "subscribes for call caller" do
    call = calls(:alice_calls_bob)
    stub_connection current_user: call.caller

    subscribe call_id: call.id

    assert subscription.confirmed?
    assert_has_stream_for call
  end

  test "subscribes for call recipient" do
    call = calls(:alice_calls_bob)
    stub_connection current_user: call.recipient

    subscribe call_id: call.id

    assert subscription.confirmed?
    assert_has_stream_for call
  end

  test "rejects unauthorized user" do
    call = calls(:alice_calls_bob)
    charlie = users(:three)
    stub_connection current_user: charlie

    subscribe call_id: call.id

    assert subscription.rejected?
  end

  test "relays messages to call participants" do
    call = calls(:alice_calls_bob)
    stub_connection current_user: call.caller

    subscribe call_id: call.id

    perform :receive, { type: "ice_candidate", candidate: "test" }

    assert_broadcast_on(call, {
      "type" => "ice_candidate",
      "candidate" => "test",
      "action" => "receive",
      "from" => call.caller.id
    })
  end

  test "unsubscribing from active call triggers hangup" do
    call = calls(:alice_calls_bob_answered)
    call.update!(status: :active)
    stub_connection current_user: call.caller

    subscribe call_id: call.id
    assert subscription.confirmed?

    unsubscribe

    call.reload
    assert_equal "ended", call.status
  end

  test "unsubscribing from ringing call triggers hangup" do
    call = calls(:alice_calls_bob)
    stub_connection current_user: call.caller

    subscribe call_id: call.id
    assert subscription.confirmed?

    unsubscribe

    call.reload
    assert_equal "ended", call.status
  end

  test "subscribing to ended call is rejected" do
    call = calls(:alice_calls_bob_answered)
    stub_connection current_user: call.caller

    subscribe call_id: call.id

    assert subscription.rejected?
  end
end
