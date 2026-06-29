require "test_helper"

class Users::RegisterTest < ActiveSupport::TestCase
  test "creates user with valid attributes" do
    result = Users::Register.call(
      email: "register@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert result.success?
    assert result.user.persisted?
    assert_equal "register@example.com", result.user.email
    assert_nil result.errors
  end

  test "returns errors for invalid email" do
    result = Users::Register.call(
      email: "",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not result.success?
    assert_not result.user.persisted?
    assert result.errors[:email].any?
  end

  test "returns errors for password mismatch" do
    result = Users::Register.call(
      email: "mismatch@example.com",
      password: "password123",
      password_confirmation: "different123"
    )

    assert_not result.success?
    assert_not result.user.persisted?
    assert result.errors[:password_confirmation].any?
  end

  test "returns errors for short password" do
    result = Users::Register.call(
      email: "short@example.com",
      password: "short",
      password_confirmation: "short"
    )

    assert_not result.success?
    assert result.errors[:password].any?
  end
end
