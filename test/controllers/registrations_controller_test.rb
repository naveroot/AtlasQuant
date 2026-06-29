require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_url
    assert_response :success
    assert_select "h1", "Create account"
  end

  test "should create user and sign in" do
    assert_difference("User.count") do
      post registration_url, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
    user = User.find_by(email: "newuser@example.com")
    assert_equal user.id, session[:user_id]
  end

  test "should render errors for invalid registration" do
    assert_no_difference("User.count") do
      post registration_url, params: {
        user: {
          email: "",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-800"
  end
end
