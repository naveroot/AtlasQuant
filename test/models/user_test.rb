require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(email: "new@example.com", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "requires email" do
    user = User.new(password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires valid email format" do
    user = User.new(email: "invalid", password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "requires unique email" do
    user = User.new(email: users(:one).email, password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires password minimum length" do
    user = User.new(email: "short@example.com", password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "normalizes email to lowercase" do
    user = User.create!(email: "  Test@Example.COM  ", password: "password123", password_confirmation: "password123")
    assert_equal "test@example.com", user.email
  end

  test "authenticates with correct password" do
    user = users(:one)
    assert user.authenticate("password123")
  end

  test "does not authenticate with incorrect password" do
    user = users(:one)
    assert_not user.authenticate("wrongpassword")
  end
end
