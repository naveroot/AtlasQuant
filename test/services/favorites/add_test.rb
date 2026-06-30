require "test_helper"

module Favorites
  class AddTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @instrument = Moex::CurrencyFutures::List::Instrument.new(
        secid: "USDRUBF",
        shortname: "USDRUBF",
        asset_code: "USDRUBTOM"
      )
    end

    test "adds instrument to favorites" do
      instrument = @instrument
      with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
        result = Add.call(user: @user, secid: "USDRUBF")

        assert result.success?
        assert_equal "USDRUBF", result.favorite.secid
        assert_equal "USDRUBTOM", result.favorite.asset_code
      end
    end

    test "is idempotent for duplicate secid" do
      instrument = @instrument
      with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
        assert_no_difference -> { @user.favorite_instruments.count } do
          result = Add.call(user: @user, secid: favorite_instruments(:one).secid)

          assert result.success?
          assert_equal favorite_instruments(:one), result.favorite
        end
      end
    end

    test "returns error for unknown secid" do
      instrument = @instrument
      with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
        result = Add.call(user: @user, secid: "UNKNOWN")

        assert_not result.success?
        assert_match "not found", result.error
      end
    end

    test "returns error when MOEX list fails" do
      with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { raise Moex::Client::Error, "timeout" }) do
        result = Add.call(user: @user, secid: "USDRUBF")

        assert_not result.success?
        assert_match "Unable to load instruments from MOEX", result.error
      end
    end
  end
end
