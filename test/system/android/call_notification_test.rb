require "android_system_test_case"

class CallNotificationTest < AndroidSystemTestCase
  test "tapping call notification opens app" do
    fill_in "Enter your email address", with: users(:one).email_address
    fill_in "Enter your password", with: "password"
    click_button "Sign in"
    assert_text "Your Contacts"

    switch_to_native
    page.driver.appium_driver.background_app(-1)

    call = Call.create!(caller: users(:two), recipient: users(:one))
    simulate_incoming_call_notification(call_id: call.id, caller_name: users(:two).name)
    page.driver.appium_driver.open_notifications

    notification = find_element(:xpath, "//*[contains(@text, '#{users(:two).name}')]")
    assert notification.displayed?, "Notification should be visible"
    notification.click

    switch_to_webview
    assert_text users(:two).name
  end

  private

  def find_element(method, selector)
    page.driver.appium_driver.find_element(method, selector)
  end
end
