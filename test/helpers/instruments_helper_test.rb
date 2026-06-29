require "test_helper"

class InstrumentsHelperTest < ActionView::TestCase
  include InstrumentsHelper

  test "candlestick_chart_data maps candles to chart payload" do
    candle = Moex::CurrencyFutures::HistoricalCandles::Candle.new(
      traded_at: Time.zone.parse("2025-06-02 00:00:00"),
      open: 79.1,
      high: 79.76,
      low: 79.05,
      close: 79.19,
      volume: 118052
    )

    data = candlestick_chart_data([ candle ])

    assert_equal 1, data.size
    assert_equal "2025-06-02", data.first[:time]
    assert_in_delta 79.19, data.first[:close]
  end

  test "instrument_summary calculates change and range" do
    candles = [
      Moex::CurrencyFutures::HistoricalCandles::Candle.new(
        traded_at: Time.zone.parse("2025-06-01 00:00:00"),
        open: 78.0, high: 79.0, low: 77.5, close: 78.5, volume: 1000
      ),
      Moex::CurrencyFutures::HistoricalCandles::Candle.new(
        traded_at: Time.zone.parse("2025-06-02 00:00:00"),
        open: 79.1, high: 80.0, low: 79.0, close: 79.5, volume: 2000
      )
    ]

    summary = instrument_summary(candles)

    assert_in_delta 79.5, summary[:last_close]
    assert_in_delta 1.0, summary[:change]
    assert_in_delta 77.5, summary[:low]
    assert_in_delta 80.0, summary[:high]
    assert_equal 3000, summary[:volume]
  end
end
