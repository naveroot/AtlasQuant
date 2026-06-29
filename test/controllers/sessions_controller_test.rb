require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_url
    assert_response :success
    assert_select "h1", "Sign in"
  end

  test "should sign in with valid credentials" do
    post session_url, params: { session: { email: users(:one).email, password: "password123" } }

    assert_redirected_to root_url
    assert_equal users(:one).id, session[:user_id]
  end

  test "should reject invalid credentials" do
    post session_url, params: { session: { email: users(:one).email, password: "wrongpassword" } }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_select ".text-red-800", /Invalid email or password/
  end

  test "should sign out" do
    post session_url, params: { session: { email: users(:one).email, password: "password123" } }
    delete session_url

    assert_redirected_to root_url
    assert_nil session[:user_id]
  end
end
