require "application_system_test_case"

class MultiDeviceDismissTest < ApplicationSystemTestCase
  setup do
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

  test "answering call on one device dismisses incoming call UI on other devices" do
    alice = users(:one)
    charlie = users(:three)

    using_session(:alice_device_1) do
      sign_in_as(alice)
      visit contacts_path
      assert_text "Your Contacts"
    end

    using_session(:alice_device_2) do
      sign_in_as(alice)
      visit contacts_path
      assert_text "Your Contacts"
    end

    using_session(:charlie_device) do
      sign_in_as(charlie)
      visit contacts_path
      click_button "Call", match: :first
      assert_text "Calling Alice"
    end

    using_session(:alice_device_1) do
      visit contacts_path
      assert_selector ".incoming-call-overlay:not(.hidden)", wait: 10
      assert_text "Charlie is calling..."
    end

    using_session(:alice_device_2) do
      visit contacts_path
      assert_selector ".incoming-call-overlay:not(.hidden)", wait: 10
      assert_text "Charlie is calling..."
    end

    using_session(:alice_device_1) do
      click_button "Answer"
      assert_current_path(/\/calls\/\d+/, wait: 5)
    end

    using_session(:alice_device_2) do
      visit contacts_path
      assert_no_selector ".incoming-call-overlay:not(.hidden)"
    end
  end
end
