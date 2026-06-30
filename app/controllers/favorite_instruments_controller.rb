class FavoriteInstrumentsController < ApplicationController
  before_action :require_login

  def index
    @favorites = current_user.favorite_instruments.order(created_at: :desc)
  end

  def create
    result = Favorites::Add.call(user: current_user, secid: instrument_secid)

    if result.success?
      redirect_back fallback_location: favorites_path, notice: "#{instrument_secid} added to favorites."
    else
      redirect_back fallback_location: favorites_path, alert: result.error
    end
  end

  def destroy
    result = Favorites::Remove.call(user: current_user, secid: instrument_secid)

    if result.success?
      redirect_back fallback_location: favorites_path, notice: "#{instrument_secid} removed from favorites."
    else
      redirect_back fallback_location: favorites_path, alert: result.error
    end
  end

  private

  def instrument_secid
    params[:instrument_secid]
  end
end
