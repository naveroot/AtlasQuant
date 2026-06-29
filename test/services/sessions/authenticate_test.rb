require "test_helper"

class Sessions::AuthenticateTest < ActiveSupport::TestCase
  test "authenticates with valid credentials" do
    result = Sessions::Authenticate.call(email: users(:one).email, password: "password123")

    assert result.success?
    assert_equal users(:one), result.user
    assert_nil result.error
  end

  test "rejects invalid password" do
    result = Sessions::Authenticate.call(email: users(:one).email, password: "wrongpassword")

    assert_not result.success?
    assert_nil result.user
    assert_equal "Invalid email or password", result.error
  end

  test "rejects unknown email" do
    result = Sessions::Authenticate.call(email: "unknown@example.com", password: "password123")

    assert_not result.success?
    assert_nil result.user
    assert_equal "Invalid email or password", result.error
  end

  test "normalizes email for lookup" do
    result = Sessions::Authenticate.call(email: "  USER@EXAMPLE.COM  ", password: "password123")

    assert result.success?
    assert_equal users(:one), result.user
  end
end
