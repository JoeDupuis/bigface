require "test_helper"
require "capybara/cuprite"

Capybara.test_id = "data-qa"
Capybara.add_selector(:test_id) do
  xpath do |locator|
    XPath.descendant[XPath.attr(Capybara.test_id) == locator]
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :chrome, screen_size: [ 1400, 1400 ], options: {
    headless: true,
    process_timeout: 20
  }
end
