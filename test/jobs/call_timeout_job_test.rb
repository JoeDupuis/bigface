require "test_helper"

class CallTimeoutJobTest < ActiveJob::TestCase
  test "marks ringing call as missed" do
    call = calls(:alice_calls_bob)
    assert call.ringing?

    CallTimeoutJob.perform_now(call.id)

    call.reload
    assert call.missed?
    assert_not_nil call.ended_at
  end

  test "ignores answered calls" do
    call = calls(:alice_calls_bob)
    call.update!(status: :active, started_at: Time.current)

    CallTimeoutJob.perform_now(call.id)

    call.reload
    assert call.active?
  end

  test "ignores ended calls" do
    call = calls(:alice_calls_bob)
    call.update!(status: :ended, ended_at: Time.current, started_at: Time.current)

    CallTimeoutJob.perform_now(call.id)

    call.reload
    assert call.ended?
  end

  test "ignores declined calls" do
    call = calls(:alice_calls_bob)
    call.update!(status: :declined, ended_at: Time.current)

    CallTimeoutJob.perform_now(call.id)

    call.reload
    assert call.declined?
  end

  test "handles non-existent call" do
    assert_nothing_raised do
      CallTimeoutJob.perform_now(-1)
    end
  end
end
