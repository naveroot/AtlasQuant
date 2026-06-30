class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    result = Users::Register.call(
      email: registration_params[:email],
      password: registration_params[:password],
      password_confirmation: registration_params[:password_confirmation]
    )

    if result.success?
      session[:user_id] = result.user.id
      Analytics::TrackEvent.track_signup(user: result.user)
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      @user = result.user
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
