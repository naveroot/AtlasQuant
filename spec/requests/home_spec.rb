require "rails_helper"

RSpec.describe "Home", type: :request do
  it "returns success on index" do
    get root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Atlas Quant")
  end

  it "shows sign in links when logged out" do
    get root_path
    expect(response.body).to include("Sign in")
    expect(response.body).to include("Sign up")
  end

  it "shows user email when logged in" do
    post session_path, params: { session: { email: users(:one).email, password: "password123" } }
    get root_path

    expect(response.body).to include(users(:one).email)
  end
end
