require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "registers push device from cookie" do
    alice = users(:one)
    sign_in_as(alice)
    cookies[:push_token] = "fcm_token_123"

    assert_difference "ApplicationPushDevice.count", 1 do
      get contacts_path
    end

    device = ApplicationPushDevice.find_by(token: "fcm_token_123")
    assert_equal alice, device.owner
    assert_equal "google", device.platform
  end

  test "does not re-register same push device on subsequent requests" do
    alice = users(:one)
    sign_in_as(alice)
    cookies[:push_token] = "fcm_token_456"

    get contacts_path
    assert_equal 1, ApplicationPushDevice.where(token: "fcm_token_456").count

    assert_no_difference "ApplicationPushDevice.count" do
      get contacts_path
    end
  end

  test "re-registers push device when db record is missing but session thinks it is registered" do
    alice = users(:one)
    sign_in_as(alice)
    cookies[:push_token] = "fcm_token_789"

    get contacts_path
    device = ApplicationPushDevice.find_by(token: "fcm_token_789")
    assert device.present?

    device.destroy!

    assert_difference "ApplicationPushDevice.count", 1 do
      get contacts_path
    end

    device = ApplicationPushDevice.find_by(token: "fcm_token_789")
    assert device.present?
    assert_equal alice, device.owner
  end

  test "does not register push device when not logged in" do
    cookies[:push_token] = "fcm_token_anonymous"

    assert_no_difference "ApplicationPushDevice.count" do
      get new_session_path
    end
  end

  test "does not register push device when token is blank" do
    alice = users(:one)
    sign_in_as(alice)
    cookies[:push_token] = ""

    assert_no_difference "ApplicationPushDevice.count" do
      get contacts_path
    end
  end
end
