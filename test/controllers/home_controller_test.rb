require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows greeting with user name" do
    user = users(:one)
    sign_in_as(user)

    get root_path

    assert_response :success
    assert_select "h1", "Hello, Alice"
  end
end
