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

  test "POST /calls/:call_id/answer as recipient answers the call" do
    call = calls(:alice_calls_bob)
    bob = users(:two)
    bob_session = sessions(:bob_session)
    sign_in_as(bob, session: bob_session)

    post call_answer_path(call)

    call.reload
    assert call.active?
    assert_not_nil call.started_at
    assert_equal bob_session, call.answered_by_session
    assert_redirected_to call_path(call)
  end

  test "POST /calls/:call_id/answer as caller returns forbidden" do
    call = calls(:alice_calls_bob)
    alice = users(:one)
    sign_in_as(alice)

    post call_answer_path(call)

    call.reload
    assert call.ringing?
    assert_response :forbidden
  end

  test "POST /calls/:call_id/answer when not ringing returns error" do
    call = calls(:alice_calls_bob)
    call.update!(status: :ended, ended_at: Time.current)
    bob = users(:two)
    sign_in_as(bob)

    post call_answer_path(call)

    assert_response :unprocessable_entity
    call.reload
    assert call.ended?
  end

  test "POST /calls/:call_id/decline as recipient declines the call" do
    call = calls(:alice_calls_bob)
    bob = users(:two)
    sign_in_as(bob)

    post call_decline_path(call)

    call.reload
    assert call.declined?
    assert_not_nil call.ended_at
    assert_redirected_to contacts_path
  end

  test "POST /calls/:call_id/decline as caller returns forbidden" do
    call = calls(:alice_calls_bob)
    alice = users(:one)
    sign_in_as(alice)

    post call_decline_path(call)

    call.reload
    assert call.ringing?
    assert_response :forbidden
  end

  test "POST /calls/:call_id/answer broadcasts to call channel" do
    call = calls(:alice_calls_bob)
    bob = users(:two)
    bob_session = sessions(:bob_session)
    sign_in_as(bob, session: bob_session)

    assert_broadcasts(CallChannel.broadcasting_for(call), 1) do
      post call_answer_path(call)
    end
  end

  test "POST /calls/:call_id/decline broadcasts to call channel" do
    call = calls(:alice_calls_bob)
    bob = users(:two)
    sign_in_as(bob)

    assert_broadcasts(CallChannel.broadcasting_for(call), 1) do
      post call_decline_path(call)
    end
  end
end
