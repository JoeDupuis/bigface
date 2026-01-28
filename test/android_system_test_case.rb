require "test_helper"
require "appium_capybara"

class AndroidSystemTestCase < ActionDispatch::SystemTestCase
  ANDROID_TEST_PORT = 45678
  APP_PACKAGE = "io.dupuis.bigface.e2e"

  Capybara.register_driver :appium_android do |app|
    device = ENV.fetch("ANDROID_DEVICE", "emulator-5554")

    opts = {
      url: ENV.fetch("APPIUM_SERVER_URL", "http://127.0.0.1:4723"),
      caps: {
        platformName: "Android",
        "appium:automationName": "UiAutomator2",
        "appium:udid": device,
        "appium:appPackage": APP_PACKAGE,
        "appium:appActivity": "io.dupuis.bigface.MainActivity",
        "appium:noReset": false,
        "appium:fullReset": false,
        "appium:autoGrantPermissions": true,
        "appium:chromedriverAutodownload": true,
        "appium:newCommandTimeout": 300
      }
    }

    Appium::Capybara::Driver.new(app, **opts)
  end

  driven_by :appium_android

  Capybara.server_port = ANDROID_TEST_PORT
  Capybara.server_host = "0.0.0.0"

  @app_installed = false

  class << self
    attr_accessor :app_installed

    def ensure_appium_running
      return if system("curl -s http://127.0.0.1:4723/status > /dev/null 2>&1")

      puts "Starting Appium..."
      pid = spawn("npx appium --allow-insecure='*:chromedriver_autodownload'",
                  out: "/dev/null", err: "/dev/null")
      Process.detach(pid)

      30.times do
        if system("curl -s http://127.0.0.1:4723/status > /dev/null 2>&1")
          puts "Appium ready"
          return
        end
        sleep 1
      end
      raise "Appium failed to start"
    end

    def ensure_app_installed
      return if app_installed
      ensure_appium_running

      device = ENV.fetch("ANDROID_DEVICE", "emulator-5554")
      clean = ENV["ANDROID_CLEAN_INSTALL"] == "1"

      if clean
        system("adb -s #{device} uninstall #{APP_PACKAGE} 2>/dev/null")
      end

      build_and_install_app(device)
      setup_adb_reverse(device)
      self.app_installed = true
    end

    def build_and_install_app(device)
      android_dir = Rails.root.join("android")
      Dir.chdir(android_dir) do
        env = { "SERVER_URL" => "http://localhost:#{ANDROID_TEST_PORT}/" }
        system(env, "./gradlew assembleE2eDebug") || raise("Failed to build Android app")
      end

      apk_path = android_dir.join("app/build/outputs/apk/e2e/debug/app-e2e-debug.apk")
      system("adb -s #{device} install -r #{apk_path}") || raise("Failed to install app")
    end

    def setup_adb_reverse(device)
      system("adb -s #{device} reverse tcp:#{ANDROID_TEST_PORT} tcp:#{ANDROID_TEST_PORT}")
    end
  end

  setup do
    self.class.ensure_app_installed
    page.driver.appium_driver.activate_app(APP_PACKAGE)
    sleep 1
    switch_to_webview
  end

  teardown do
    clear_app_notifications
    begin
      page.driver.quit if page.driver.respond_to?(:quit)
    rescue StandardError
    end
    Capybara.reset_sessions!
  end

  def clear_app_notifications
    device = ENV.fetch("ANDROID_DEVICE", "emulator-5554")
    system("adb -s #{device} shell pm clear-notifications #{APP_PACKAGE} 2>/dev/null") ||
      system("adb -s #{device} shell cmd notification cancel_all #{APP_PACKAGE} 2>/dev/null")
  end

  def switch_to_webview(timeout: 10)
    driver = page.driver.appium_driver
    wait_until(timeout) do
      contexts = driver.available_contexts
      webview = contexts.find { |c| c.include?(APP_PACKAGE) } || contexts.find { |c| c.start_with?("WEBVIEW") }
      if webview
        driver.set_context(webview)
        true
      else
        false
      end
    end
  end

  def switch_to_native
    page.driver.appium_driver.set_context("NATIVE_APP")
  end

  def simulate_incoming_call_notification(call_id:, caller_name:)
    device = ENV.fetch("ANDROID_DEVICE", "emulator-5554")
    cmd = "adb -s #{device} shell am broadcast " \
          "-a io.dupuis.bigface.DEBUG_INCOMING_CALL " \
          "-n #{APP_PACKAGE}/io.dupuis.bigface.DebugMessagingReceiver " \
          "--es call_id '#{call_id}' " \
          "--es caller_name '#{caller_name}'"
    system(cmd)
  end

  private

  def wait_until(timeout, &block)
    start = Time.now
    until block.call
      raise "Timeout waiting for condition" if Time.now - start > timeout
      sleep 0.5
    end
  end
end
