require "rails_helper"

RSpec.describe Users::Register do
  it "creates user with valid attributes" do
    result = described_class.call(
      email: "register@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    expect(result).to be_success
    expect(result.user).to be_persisted
    expect(result.user.email).to eq("register@example.com")
    expect(result.errors).to be_nil
  end

  it "returns errors for invalid email" do
    result = described_class.call(
      email: "",
      password: "password123",
      password_confirmation: "password123"
    )

    expect(result).not_to be_success
    expect(result.user).not_to be_persisted
    expect(result.errors[:email]).to be_any
  end

  it "returns errors for password mismatch" do
    result = described_class.call(
      email: "mismatch@example.com",
      password: "password123",
      password_confirmation: "different123"
    )

    expect(result).not_to be_success
    expect(result.user).not_to be_persisted
    expect(result.errors[:password_confirmation]).to be_any
  end

  it "returns errors for short password" do
    result = described_class.call(
      email: "short@example.com",
      password: "short",
      password_confirmation: "short"
    )

    expect(result).not_to be_success
    expect(result.errors[:password]).to be_any
  end
end
