require "test_helper"

class CallsControllerTest < ActionDispatch::IntegrationTest
  test "POST /calls with valid recipient creates call and redirects" do
    bob = users(:two)
    alice = users(:one)
    sign_in_as(bob)

    assert_difference "Call.count", 1 do
      post calls_path, params: { call: { recipient_id: alice.id } }
    end

    call = Call.last
    assert_equal bob, call.caller
    assert_equal alice, call.recipient
    assert call.ringing?
    assert_redirected_to call_path(call)
  end

  test "POST /calls with non-contact returns error" do
    alice = users(:one)
    dan = users(:four)
    sign_in_as(alice)

    assert_no_difference "Call.count" do
      post calls_path, params: { call: { recipient_id: dan.id } }
    end

    assert_response :unprocessable_entity
  end

  test "POST /calls when already in a ringing call returns error" do
    alice = users(:one)
    charlie = users(:three)
    sign_in_as(alice)

    assert_no_difference "Call.count" do
      post calls_path, params: { call: { recipient_id: charlie.id } }
    end

    assert_response :unprocessable_entity
  end

  test "GET /calls/:id as caller shows call page" do
    alice = users(:one)
    call = calls(:alice_calls_bob)
    sign_in_as(alice)

    get call_path(call)

    assert_response :success
    assert_select "p", text: /Calling Bob/
  end

  test "GET /calls/:id as recipient shows call page" do
    bob = users(:two)
    call = calls(:alice_calls_bob)
    sign_in_as(bob)

    get call_path(call)

    assert_response :success
  end

  test "GET /calls/:id as unrelated user returns 404" do
    charlie = users(:three)
    call = calls(:alice_calls_bob)
    sign_in_as(charlie)

    get call_path(call)

    assert_response :not_found
  end

  test "POST /calls when not logged in redirects to login" do
    bob = users(:two)

    post calls_path, params: { call: { recipient_id: bob.id } }

    assert_redirected_to new_session_path
  end

  test "creating call broadcasts to recipient" do
    bob = users(:two)
    alice = users(:one)
    sign_in_as(bob)

    assert_broadcasts(UserNotificationChannel.broadcasting_for(alice), 1) do
      post calls_path, params: { call: { recipient_id: alice.id } }
    end
  end
end
