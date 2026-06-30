require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with valid attributes" do
    user = User.new(email: "new@example.com", password: "password123", password_confirmation: "password123")
    expect(user).to be_valid
  end

  it "requires email" do
    user = User.new(password: "password123", password_confirmation: "password123")
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it "requires valid email format" do
    user = User.new(email: "invalid", password: "password123", password_confirmation: "password123")
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("is invalid")
  end

  it "requires unique email" do
    user = User.new(email: users(:one).email, password: "password123", password_confirmation: "password123")
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("has already been taken")
  end

  it "requires password minimum length" do
    user = User.new(email: "short@example.com", password: "short", password_confirmation: "short")
    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
  end

  it "normalizes email to lowercase" do
    user = User.create!(email: "  Test@Example.COM  ", password: "password123", password_confirmation: "password123")
    expect(user.email).to eq("test@example.com")
  end

  it "authenticates with correct password" do
    user = users(:one)
    expect(user.authenticate("password123")).to eq(user)
  end

  it "does not authenticate with incorrect password" do
    user = users(:one)
    expect(user.authenticate("wrongpassword")).to be_falsey
  end
end
