require "test_helper"

class Favorites::AddTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @user = users(:one)
  end

  test "adds favorite for valid secid" do
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "CNYRUBF",
      shortname: "CNYRUBF",
      asset_code: "CNYRUBTOM"
    )
    result = nil

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      result = Favorites::Add.call(user: @user, secid: "CNYRUBF")
    end

    assert result.success?
    assert_equal "CNYRUBF", result.favorite.secid
    assert_equal @user, result.favorite.user
  end

  test "rejects unknown secid" do
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )
    result = nil

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      result = Favorites::Add.call(user: @user, secid: "UNKNOWN")
    end

    assert_not result.success?
    assert_includes result.errors.full_messages.join, "not a valid MOEX instrument"
  end

  test "rejects duplicate favorite" do
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: favorites(:one_usdrubf).secid,
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )
    result = nil

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      result = Favorites::Add.call(user: @user, secid: favorites(:one_usdrubf).secid)
    end

    assert_not result.success?
    assert_includes result.errors.full_messages.join, "has already been taken"
  end
end
