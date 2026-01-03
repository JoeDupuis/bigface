require "application_system_test_case"

class MultiDeviceDismissTest < ApplicationSystemTestCase
  test "answering call on one device dismisses incoming call UI on other devices" do
    alice = users(:one)
    bob = users(:two)

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

    using_session(:bob_device) do
      sign_in_as(bob)
      visit contacts_path
      click_button "Call", match: :first
      assert_text "Calling Alice"
    end

    using_session(:alice_device_1) do
      assert_selector ".incoming-call-overlay:not(.hidden)", wait: 10
      assert_text "Bob is calling..."
    end

    using_session(:alice_device_2) do
      assert_selector ".incoming-call-overlay:not(.hidden)", wait: 10
      assert_text "Bob is calling..."
    end

    using_session(:alice_device_1) do
      click_button "Answer"
      assert_current_path(/\/calls\/\d+/, wait: 5)
    end

    using_session(:alice_device_2) do
      assert_selector ".incoming-call-overlay.hidden", visible: :all, wait: 10
    end
  end
end
