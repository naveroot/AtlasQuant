class FavoritesController < ApplicationController
  before_action :require_login

  def index
    favorite_secids = current_user.favorites.order(created_at: :desc).pluck(:secid)
    instruments_by_secid = load_instruments_by_secid

    @favorites = favorite_secids.map do |secid|
      instruments_by_secid[secid] || missing_instrument(secid)
    end
  end

  def create
    result = Favorites::Add.call(user: current_user, secid: secid_param)

    if result.success?
      redirect_back fallback_location: favorites_path, notice: "Added to favorites."
    else
      redirect_back fallback_location: instruments_path, alert: result.errors.full_messages.to_sentence
    end
  end

  def destroy
    result = Favorites::Remove.call(user: current_user, secid: params[:secid])

    if result.success?
      redirect_back fallback_location: favorites_path, notice: "Removed from favorites."
    else
      redirect_back fallback_location: favorites_path, alert: result.errors.full_messages.to_sentence
    end
  end

  private

  def secid_param
    params[:secid].presence || params.dig(:favorite, :secid)
  end

  def load_instruments_by_secid
    Moex::CurrencyFutures::List.call.index_by(&:secid)
  rescue Moex::Client::Error
    {}
  end

  def missing_instrument(secid)
    Moex::CurrencyFutures::List::Instrument.new(
      secid:,
      shortname: secid,
      asset_code: "—"
    )
  end
end
