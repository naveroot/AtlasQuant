require "test_helper"

class InstrumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "index lists currency futures" do
    instruments = [
      Moex::CurrencyFutures::List::Instrument.new(secid: "USDRUBF", shortname: "USDRUBF", asset_code: "USDRUBTOM")
    ]

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { instruments }) do
      get instruments_path
    end

    assert_response :success
    assert_match "USDRUBF", response.body
    assert_match "Currency Futures", response.body
  end

  test "index shows alert when MOEX is unavailable" do
    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { raise Moex::Client::Error, "timeout" }) do
      get instruments_path
    end

    assert_response :success
    assert_match "Unable to load instruments from MOEX", response.body
  end

  test "show renders chart page for known instrument" do
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )
    candle = Moex::CurrencyFutures::HistoricalCandles::Candle.new(
      traded_at: Time.zone.parse("2025-06-02 00:00:00"),
      open: 79.1,
      high: 79.76,
      low: 79.05,
      close: 79.19,
      volume: 118052
    )

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      with_stubbed_class_method(Moex::CurrencyFutures::HistoricalCandles, :call, ->(**) { [ candle ] }) do
        get instrument_path("USDRUBF")
      end
    end

    assert_response :success
    assert_match "USDRUBF", response.body
    assert_match "price-chart", response.body
    assert_match "79.19", response.body
  end

  test "show redirects for unknown instrument" do
    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [] }) do
      get instrument_path("UNKNOWN")
    end

    assert_redirected_to instruments_path
    assert_equal "Instrument UNKNOWN not found.", flash[:alert]
  end

  test "show redirects when MOEX candles request fails" do
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      with_stubbed_class_method(Moex::CurrencyFutures::HistoricalCandles, :call, ->(**) { raise Moex::Client::Error, "timeout" }) do
        get instrument_path("USDRUBF")
      end
    end

    assert_redirected_to instruments_path
    assert_match "Unable to load chart data from MOEX", flash[:alert]
  end
end
