require "rails_helper"

RSpec.describe Sessions::Authenticate do
  it "authenticates with valid credentials" do
    result = described_class.call(email: users(:one).email, password: "password123")

    expect(result).to be_success
    expect(result.user).to eq(users(:one))
    expect(result.error).to be_nil
  end

  it "rejects invalid password" do
    result = described_class.call(email: users(:one).email, password: "wrongpassword")

    expect(result).not_to be_success
    expect(result.user).to be_nil
    expect(result.error).to eq("Invalid email or password")
  end

  it "rejects unknown email" do
    result = described_class.call(email: "unknown@example.com", password: "password123")

    expect(result).not_to be_success
    expect(result.user).to be_nil
    expect(result.error).to eq("Invalid email or password")
  end

  it "normalizes email for lookup" do
    result = described_class.call(email: "  USER@EXAMPLE.COM  ", password: "password123")

    expect(result).to be_success
    expect(result.user).to eq(users(:one))
  end
end
