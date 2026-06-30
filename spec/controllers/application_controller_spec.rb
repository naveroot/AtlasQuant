require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action :require_login

    def index
      render plain: "ok"
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  it "redirects to sign in when not logged in" do
    get :index
    expect(response).to redirect_to(new_session_path)
    expect(flash[:alert]).to eq("Please sign in to continue.")
  end

  it "allows access when logged in" do
    session[:user_id] = users(:one).id
    get :index
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("ok")
  end
end
