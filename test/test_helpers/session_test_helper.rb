module SessionTestHelper
  def sign_in_as(user, session: nil)
    Current.session = session || user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id

      if respond_to?(:page)
        if page.driver.is_a?(Appium::Capybara::Driver)
          page.driver.appium_driver.manage.add_cookie(name: "session_id", value: cookie_jar[:session_id])
          page.driver.browser.navigate.to("http://localhost:#{Capybara.server_port}")
        else
          page.driver.set_cookie("session_id", cookie_jar[:session_id])
        end
      else
        cookies["session_id"] = cookie_jar[:session_id]
      end
    end
  end

  def sign_out
    Current.session&.destroy!
    if respond_to?(:page)
      page.driver.remove_cookie("session_id")
    else
      cookies.delete("session_id")
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end

ActiveSupport.on_load(:action_dispatch_system_test_case) do
  include SessionTestHelper
end
