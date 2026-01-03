require "test_helper"

class CallTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  test "requires caller" do
    call = Call.new(recipient: users(:one))
    assert_not call.valid?
    assert_includes call.errors[:caller], "must exist"
  end

  test "requires recipient" do
    call = Call.new(caller: users(:one))
    assert_not call.valid?
    assert_includes call.errors[:recipient], "must exist"
  end

  test "defaults to ringing status" do
    call = Call.new
    assert_equal "ringing", call.status
  end

  test "answer! transitions to active" do
    call = calls(:alice_calls_bob)
    session = sessions(:alice_session)

    call.answer!(session)

    assert call.active?
    assert_not_nil call.started_at
    assert_equal session, call.answered_by_session
  end

  test "answer! fails if not ringing" do
    call = calls(:alice_calls_bob)
    call.update!(status: :ended, ended_at: Time.current)

    assert_raises(Call::InvalidTransition) do
      call.answer!(sessions(:alice_session))
    end
  end

  test "end! transitions to ended" do
    call = calls(:alice_calls_bob)
    call.update!(status: :active, started_at: Time.current)

    call.end!

    assert call.ended?
    assert_not_nil call.ended_at
  end

  test "end! fails if not active" do
    call = calls(:alice_calls_bob)

    assert_raises(Call::InvalidTransition) do
      call.end!
    end
  end

  test "decline! transitions to declined" do
    call = calls(:alice_calls_bob)

    call.decline!

    assert call.declined?
    assert_not_nil call.ended_at
  end

  test "decline! fails if not ringing" do
    call = calls(:alice_calls_bob)
    call.update!(status: :active, started_at: Time.current)

    assert_raises(Call::InvalidTransition) do
      call.decline!
    end
  end

  test "miss! transitions to missed" do
    call = calls(:alice_calls_bob)

    call.miss!

    assert call.missed?
    assert_not_nil call.ended_at
  end

  test "miss! fails if not ringing" do
    call = calls(:alice_calls_bob)
    call.update!(status: :active, started_at: Time.current)

    assert_raises(Call::InvalidTransition) do
      call.miss!
    end
  end

  test "active scope returns active calls" do
    call = calls(:alice_calls_bob)
    call.update!(status: :active, started_at: Time.current)

    assert_includes Call.active, call
    assert_not_includes Call.ringing, call
  end

  test "ringing scope returns ringing calls" do
    call = calls(:alice_calls_bob)

    assert_includes Call.ringing, call
    assert_not_includes Call.active, call
  end

  test "user can only have one ringing outgoing call" do
    alice = users(:one)
    bob = users(:two)

    assert calls(:alice_calls_bob).ringing?

    new_call = Call.new(caller: alice, recipient: bob)
    assert_not new_call.valid?
    assert_includes new_call.errors[:caller_id], "already has a ringing call"
  end

  test "caller and recipient must be contacts" do
    alice = users(:one)
    bob = users(:two)

    Contact.where(user: alice, contact: bob).destroy_all
    Contact.where(user: bob, contact: alice).destroy_all

    call = Call.new(caller: alice, recipient: bob)
    assert_not call.valid?
    assert_includes call.errors[:recipient], "must be a contact"
  end

  test "belongs to caller" do
    call = calls(:alice_calls_bob)
    assert_equal users(:one), call.caller
  end

  test "belongs to recipient" do
    call = calls(:alice_calls_bob)
    assert_equal users(:two), call.recipient
  end

  test "user has many outgoing_calls" do
    alice = users(:one)
    assert_includes alice.outgoing_calls, calls(:alice_calls_bob)
  end

  test "user has many incoming_calls" do
    bob = users(:two)
    assert_includes bob.incoming_calls, calls(:alice_calls_bob)
  end

  test "answer! broadcasts call_answered to user notification channel" do
    call = calls(:alice_calls_bob)
    bob = users(:two)
    session = sessions(:bob_session)

    assert_broadcasts(UserNotificationChannel.broadcasting_for(bob), 1) do
      call.answer!(session)
    end
  end

  test "timeout! transitions ringing to missed" do
    call = calls(:alice_calls_bob)
    assert call.ringing?

    call.timeout!

    assert call.missed?
    assert_not_nil call.ended_at
  end

  test "timeout! does nothing if not ringing" do
    call = calls(:alice_calls_bob)
    call.update!(status: :active, started_at: Time.current)

    call.timeout!

    assert call.active?
  end

  test "timeout! broadcasts to call channel" do
    call = calls(:alice_calls_bob)

    assert_broadcasts(CallChannel.broadcasting_for(call), 1) do
      call.timeout!
    end
  end

  test "timeout! broadcasts to recipient user notification channel" do
    call = calls(:alice_calls_bob)
    bob = users(:two)

    assert_broadcasts(UserNotificationChannel.broadcasting_for(bob), 1) do
      call.timeout!
    end
  end

  test "schedules timeout job on create" do
    bob = users(:two)
    alice = users(:one)
    Call.where(caller: alice, status: :ringing).update_all(status: :ended)

    assert_enqueued_with(job: CallTimeoutJob) do
      Call.create!(caller: alice, recipient: bob)
    end
  end
end
