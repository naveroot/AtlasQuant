require "test_helper"

class Moex::CurrencyFutures::HistoricalCandlesTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "maps daily candles into value objects" do
    captured = {}

    client = Object.new
    client.define_singleton_method(:get) do |path, params:|
      captured[:path] = path
      captured[:params] = params
      {
        candles: [
          {
            "begin" => "2025-06-02 00:00:00",
            "open" => 79.1,
            "high" => 79.76,
            "low" => 79.05,
            "close" => 79.19,
            "volume" => 118052
          }
        ]
      }
    end

    candles = Moex::CurrencyFutures::HistoricalCandles.call(
      secid: "USDRUBF",
      from: Date.new(2025, 6, 1),
      till: Date.new(2025, 6, 28),
      client:
    )

    assert_match %r{/USDRUBF/candles\.json\z}, captured[:path]
    assert_equal Date.new(2025, 6, 1).iso8601, captured[:params][:from]
    assert_equal Date.new(2025, 6, 28).iso8601, captured[:params][:till]
    assert_equal 24, captured[:params][:interval]
    assert_equal 1, candles.size
    assert_equal Date.new(2025, 6, 2), candles.first.traded_at.to_date
    assert_equal BigDecimal("79.19"), candles.first.close
    assert_equal 118052, candles.first.volume
  end

  test "returns empty array when MOEX has no candles" do
    client = Object.new
    client.define_singleton_method(:get) { |_path, params: {}| { candles: [] } }

    candles = Moex::CurrencyFutures::HistoricalCandles.call(
      secid: "USDRUBF",
      from: Date.new(2025, 6, 1),
      till: Date.new(2025, 6, 28),
      client:
    )

    assert_empty candles
  end
end
