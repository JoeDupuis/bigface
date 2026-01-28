require "android_system_test_case"

class CallNotificationTest < AndroidSystemTestCase
  test "action cable connects after login" do
    sign_in_as users(:one)
    assert_text "Your Contacts"

    state = page.evaluate_script("window.cableConsumer?.connection.getState()")
    assert_equal "open", state, "ActionCable should be connected after login"
  end

  test "incoming call shows overlay via websocket" do
    sign_in_as users(:one)
    assert_text "Your Contacts"

    url = page.evaluate_script("window.cableConsumer?.url")
    state = page.evaluate_script("window.cableConsumer?.connection.getState()")
    puts "Cable URL: #{url}, state: #{state}"

    Call.create!(caller: users(:two), recipient: users(:one))

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
    assert_text users(:two).name
  end

  private

  def find_element(method, selector)
    page.driver.appium_driver.find_element(method, selector)
  end
end
