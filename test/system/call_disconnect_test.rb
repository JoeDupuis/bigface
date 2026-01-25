require "application_system_test_case"

class CallDisconnectTest < ApplicationSystemTestCase
  setup do
    stub_turn_credentials
  end

  test "closing browser during active call ends call for other party" do
    alice = users(:one)
    bob = users(:two)

    using_session(:alice) do
      sign_in_as(alice)
      visit contacts_path
      assert_text "Your Contacts"
    end

    using_session(:bob) do
      sign_in_as(bob)
      visit contacts_path
      click_button "Call", match: :first
      assert_current_path(/\/calls\/\d+/, wait: 5)
    end

    using_session(:alice) do
      assert_selector ".incoming-call-overlay:not(.hidden)", wait: 10
      click_button "Answer"
      assert_current_path(/\/calls\/\d+/, wait: 5)
    end

    sleep 1

    using_session(:bob) do
      visit "about:blank"
    end

    using_session(:alice) do
      assert_current_path contacts_path, wait: 10
    end
  end

  test "refreshing browser during active call redirects to contacts" do
    alice = users(:one)
    bob = users(:two)

    using_session(:alice) do
      sign_in_as(alice)
      visit contacts_path
      assert_text "Your Contacts"
    end

    using_session(:bob) do
      sign_in_as(bob)
      visit contacts_path
      click_button "Call", match: :first
      assert_current_path(/\/calls\/\d+/, wait: 5)
      @call_path = current_path
    end

    using_session(:alice) do
      assert_selector ".incoming-call-overlay:not(.hidden)", wait: 10
      click_button "Answer"
      assert_current_path(/\/calls\/\d+/, wait: 5)
    end

    sleep 1

    using_session(:bob) do
      visit @call_path
      assert_current_path contacts_path, wait: 5
    end
  end

  private

  def stub_turn_credentials
    stub_request(:post, /rtc\.live\.cloudflare\.com.*credentials\/generate/)
      .to_return(
        status: 200,
        body: {
          iceServers: {
            urls: [ "stun:stun.example.com:3478", "turn:turn.example.com:3478" ],
            username: "test",
            credential: "test"
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
