require "rails_helper"

RSpec.describe InstrumentsHelper, type: :helper do
  describe "#candlestick_chart_data" do
    it "maps candles to chart payload" do
      candle = Moex::CurrencyFutures::HistoricalCandles::Candle.new(
        traded_at: Time.zone.parse("2025-06-02 00:00:00"),
        open: 79.1,
        high: 79.76,
        low: 79.05,
        close: 79.19,
        volume: 118052
      )

      data = candlestick_chart_data([ candle ])

      expect(data.size).to eq(1)
      expect(data.first[:time]).to eq("2025-06-02")
      expect(data.first[:close]).to be_within(0.001).of(79.19)
    end
  end

  describe "#instrument_summary" do
    it "calculates change and range" do
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

      expect(summary[:last_close]).to be_within(0.001).of(79.5)
      expect(summary[:change]).to be_within(0.001).of(1.0)
      expect(summary[:low]).to be_within(0.001).of(77.5)
      expect(summary[:high]).to be_within(0.001).of(80.0)
      expect(summary[:volume]).to eq(3000)
    end
  end
end
