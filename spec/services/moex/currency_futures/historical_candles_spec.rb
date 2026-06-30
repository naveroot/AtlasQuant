require "rails_helper"

RSpec.describe Moex::CurrencyFutures::HistoricalCandles do
  before { Rails.cache.clear }

  it "maps daily candles into value objects" do
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

    candles = described_class.call(
      secid: "USDRUBF",
      from: Date.new(2025, 6, 1),
      till: Date.new(2025, 6, 28),
      client:
    )

    expect(captured[:path]).to match(%r{/USDRUBF/candles\.json\z})
    expect(captured[:params][:from]).to eq(Date.new(2025, 6, 1).iso8601)
    expect(captured[:params][:till]).to eq(Date.new(2025, 6, 28).iso8601)
    expect(captured[:params][:interval]).to eq(24)
    expect(candles.size).to eq(1)
    expect(candles.first.traded_at.to_date).to eq(Date.new(2025, 6, 2))
    expect(candles.first.close).to eq(BigDecimal("79.19"))
    expect(candles.first.volume).to eq(118052)
  end

  it "returns empty array when MOEX has no candles" do
    client = Object.new
    client.define_singleton_method(:get) { |_path, params: {}| { candles: [] } }

    candles = described_class.call(
      secid: "USDRUBF",
      from: Date.new(2025, 6, 1),
      till: Date.new(2025, 6, 28),
      client:
    )

    expect(candles).to be_empty
  end
end
