require "android_system_test_case"

class CallNotificationTest < AndroidSystemTestCase
  include ActiveJob::TestHelper

  test "action cable connects after login" do
    sign_in_as users(:one)
    assert_text "Your Contacts"

    state = page.evaluate_script("window.cableConsumer?.connection.getState()")
    assert_equal "open", state, "ActionCable should be connected after login"
  end

  test "incoming call shows overlay" do
    sign_in_as users(:one)
    assert_text "Your Contacts"

    Call.create!(caller: users(:two), recipient: users(:one))
    page.driver.browser.navigate.refresh

    assert_selector ".incoming-call-overlay:not(.hidden)", wait: 10
    assert_text "#{users(:two).name} is calling"
  end


  test "tapping call notification opens app" do
    sign_in_as users(:one)
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

    call.reload
    assert_equal "ringing", call.status, "Call should be active"
    assert_text "Your Contacts"
  end

  test "answering call notification opens app and joins call" do
    sign_in_as users(:one)
    assert_text "Your Contacts"

    switch_to_native
    page.driver.appium_driver.background_app(-1)

    app_state = page.driver.appium_driver.app_state(APP_PACKAGE)
    assert_equal :running_in_background, app_state, "App should be in foreground"

    call = Call.create!(caller: users(:two), recipient: users(:one))
    simulate_incoming_call_notification(call_id: call.id, caller_name: users(:two).name)

    page.driver.appium_driver.open_notifications

    answer_button = find_element(:xpath, "//*[@content-desc='Answer']")
    assert answer_button.displayed?, "Answer button should be visible"
    answer_button.click

    app_state = page.driver.appium_driver.app_state(APP_PACKAGE)
    assert_equal :running_in_foreground, app_state, "App should be in foreground"

    switch_to_webview

    call.reload
    assert_equal "active", call.status, "Call should be active"
  end

  test "declining call notification does not open app and declines call" do
    sign_in_as users(:one)
    assert_text "Your Contacts"

    switch_to_native
    page.driver.appium_driver.background_app(-1)

    call = Call.create!(caller: users(:two), recipient: users(:one))
    simulate_incoming_call_notification(call_id: call.id, caller_name: users(:two).name)
    page.driver.appium_driver.open_notifications

    decline_button = find_element(:xpath, "//*[@content-desc='Decline']")
    assert decline_button.displayed?, "Decline button should be visible"
    decline_button.click

    page.driver.appium_driver.back

    notification = find_element(:xpath, "//*[contains(@text, '#{users(:two).name}')]") rescue nil
    assert_nil notification, "Notification should be dismissed"

    app_state = page.driver.appium_driver.app_state(APP_PACKAGE)
    assert_equal :running_in_background, app_state, "App should remain in background"

    call.reload
    assert_equal "declined", call.status, "Call should be declined"
  end

  private

  def find_element(method, selector)
    page.driver.appium_driver.find_element(method, selector)
  end
end
