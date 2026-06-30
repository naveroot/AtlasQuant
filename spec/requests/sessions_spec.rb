require "rails_helper"

RSpec.describe "Sessions", type: :request do
  it "returns success on new" do
    get new_session_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Sign in")
  end

  it "signs in with valid credentials" do
    post session_path, params: { session: { email: users(:one).email, password: "password123" } }

    expect(response).to redirect_to(root_path)
    expect(session[:user_id]).to eq(users(:one).id)
  end

  it "rejects invalid credentials" do
    post session_path, params: { session: { email: users(:one).email, password: "wrongpassword" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(session[:user_id]).to be_nil
    expect(response.body).to match(/Invalid email or password/)
  end

  it "signs out" do
    post session_path, params: { session: { email: users(:one).email, password: "password123" } }
    delete session_path

    expect(response).to redirect_to(root_path)
    expect(session[:user_id]).to be_nil
  end
end
