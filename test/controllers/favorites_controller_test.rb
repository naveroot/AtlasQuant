require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "index requires login" do
    get favorites_path

    assert_redirected_to new_session_path
    assert_equal "Please sign in to continue.", flash[:alert]
  end

  test "create requires login" do
    post favorites_path, params: { secid: "USDRUBF" }

    assert_redirected_to new_session_path
    assert_equal "Please sign in to continue.", flash[:alert]
  end

  test "destroy requires login" do
    delete favorite_path("USDRUBF")

    assert_redirected_to new_session_path
    assert_equal "Please sign in to continue.", flash[:alert]
  end

  test "index lists user favorites" do
    sign_in_as(users(:one))
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      get favorites_path
    end

    assert_response :success
    assert_match "USDRUBF", response.body
    assert_match "Favorites", response.body
  end

  test "index shows empty state" do
    sign_in_as(users(:two))
    users(:two).favorites.destroy_all
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      get favorites_path
    end

    assert_response :success
    assert_match "No favorites yet", response.body
  end

  test "create adds favorite" do
    sign_in_as(users(:two))
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      assert_difference -> { users(:two).favorites.count }, 1 do
        post favorites_path, params: { secid: "USDRUBF" }
      end
    end

    assert_redirected_to favorites_path
    assert_equal "Added to favorites.", flash[:notice]
  end

  test "create rejects invalid secid" do
    sign_in_as(users(:two))
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      post favorites_path, params: { secid: "UNKNOWN" }
    end

    assert_redirected_to instruments_path
    assert_match "not a valid MOEX instrument", flash[:alert]
  end

  test "destroy removes favorite" do
    sign_in_as(users(:one))

    assert_difference -> { users(:one).favorites.count }, -1 do
      delete favorite_path(favorites(:one_usdrubf).secid)
    end

    assert_redirected_to favorites_path
    assert_equal "Removed from favorites.", flash[:notice]
  end

  test "destroy rejects missing favorite" do
    sign_in_as(users(:one))

    delete favorite_path("MISSING")

    assert_redirected_to favorites_path
    assert_match "not in favorites", flash[:alert]
  end

  private

  def sign_in_as(user)
    post session_url, params: { session: { email: user.email, password: "password123" } }
  end
end
