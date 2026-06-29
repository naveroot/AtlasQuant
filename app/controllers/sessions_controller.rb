class SessionsController < ApplicationController
  def new
  end

  def create
    result = Sessions::Authenticate.call(
      email: session_params[:email],
      password: session_params[:password]
    )

    if result.success?
      session[:user_id] = result.user.id
      redirect_to root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
