ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

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
  end
end
