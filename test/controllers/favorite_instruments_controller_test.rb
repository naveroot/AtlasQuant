require "test_helper"

class FavoriteInstrumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )
  end

  test "index requires login" do
    get favorites_path

    assert_redirected_to new_session_path
    assert_equal "Please sign in to continue.", flash[:alert]
  end

  test "index lists user favorites" do
    sign_in_as(users(:one))

    get favorites_path

    assert_response :success
    assert_select "h1", "Favorites"
    assert_select "p.font-mono", favorite_instruments(:one).secid
  end

  test "create adds favorite for logged in user" do
    sign_in_as(users(:two))
    instrument = @instrument

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      assert_difference -> { users(:two).favorite_instruments.count }, 1 do
        post instrument_favorite_path("USDRUBF")
      end
    end

    assert_redirected_to favorites_path
    assert_equal "USDRUBF added to favorites.", flash[:notice]
  end

  test "create requires login" do
    post instrument_favorite_path("USDRUBF")

    assert_redirected_to new_session_path
  end

  test "create shows error for unknown instrument" do
    sign_in_as(users(:two))
    instrument = @instrument

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      post instrument_favorite_path("UNKNOWN")
    end

    assert_redirected_to favorites_path
    assert_match "not found", flash[:alert]
  end

  test "destroy removes favorite" do
    sign_in_as(users(:one))

    assert_difference -> { users(:one).favorite_instruments.count }, -1 do
      delete instrument_favorite_path(favorite_instruments(:one).secid)
    end

    assert_redirected_to favorites_path
    assert_equal "#{favorite_instruments(:one).secid} removed from favorites.", flash[:notice]
  end

  test "destroy requires login" do
    delete instrument_favorite_path(favorite_instruments(:one).secid)

    assert_redirected_to new_session_path
  end

  test "destroy shows error when not in favorites" do
    sign_in_as(users(:two))

    delete instrument_favorite_path("UNKNOWN")

    assert_redirected_to favorites_path
    assert_match "not in favorites", flash[:alert]
  end

  private

  def sign_in_as(user)
    post session_url, params: { session: { email: user.email, password: "password123" } }
  end
end
