ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require_relative "test_helpers/session_test_helper"

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    include SessionTestHelper

    def sop
      save_and_open_page
    end

    def sos
      save_and_open_screenshot
    end

    def with_test_cable_adapter(&block)
      old_adapter = ActionCable.server.config.cable
      ActionCable.server.config.cable = { "adapter" => "test" }
      ActionCable.server.restart
      yield
    ensure
      ActionCable.server.config.cable = old_adapter
      ActionCable.server.restart
    end
  end
end
