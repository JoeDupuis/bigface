require "android_system_test_case"

class AndroidSmokeTest < AndroidSystemTestCase
  test "user can sign in" do
    assert_button "Sign in"

    sign_in_as users(:one)
    assert_text "Your Contacts"
  end
end
