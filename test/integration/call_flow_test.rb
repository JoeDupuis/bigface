require "test_helper"

class CallFlowTest < ActionDispatch::IntegrationTest
  test "start call flow" do
    bob = users(:two)
    alice = users(:one)
    sign_in_as(bob)

    get contacts_path
    assert_response :success
    assert_select ".contact-card .name", text: /Alice/

    assert_difference "Call.count", 1 do
      post calls_path, params: { call: { recipient_id: alice.id } }
    end

    call = Call.last
    assert_redirected_to call_path(call)

    follow_redirect!
    assert_response :success
    assert_select "p", text: /Calling Alice/
  end
end
