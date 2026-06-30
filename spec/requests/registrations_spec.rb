require "rails_helper"

RSpec.describe "Registrations", type: :request do
  it "returns success on new" do
    get new_registration_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Create account")
  end

  it "creates user and signs in" do
    expect {
      post registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    }.to change(User, :count).by(1)

    expect(response).to redirect_to(root_path)
    user = User.find_by(email: "newuser@example.com")
    expect(session[:user_id]).to eq(user.id)
  end

  it "renders errors for invalid registration" do
    expect {
      post registration_path, params: {
        user: {
          email: "",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    }.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("text-red-800")
  end
end
