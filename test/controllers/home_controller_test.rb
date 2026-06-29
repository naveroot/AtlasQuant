require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
    assert_select "h1", "Atlas Quant"
  end

  test "shows sign in links when logged out" do
    get root_url
    assert_select "a", text: "Sign in"
    assert_select "a", text: "Sign up"
  end

  test "shows user email when logged in" do
    post session_url, params: { session: { email: users(:one).email, password: "password123" } }
    get root_url

    assert_select "span.font-medium", users(:one).email
  end
end
