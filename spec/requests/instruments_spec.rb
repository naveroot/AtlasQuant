require "rails_helper"

RSpec.describe "Instruments", type: :request do
  before { Rails.cache.clear }

  it "lists currency futures as cards" do
    instruments = [
      Moex::CurrencyFutures::List::Instrument.new(secid: "USDRUBF", shortname: "USDRUBF", asset_code: "USDRUBTOM")
    ]

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { instruments }) do
      get instruments_path
    end

    expect(response).to have_http_status(:success)
    expect(response.body).to include("USDRUBF")
    expect(response.body).to include("Currency Futures")
    expect(response.body).to include("View chart")
    expect(response.body).not_to include("<table")
  end

  it "shows alert when MOEX is unavailable" do
    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { raise Moex::Client::Error, "timeout" }) do
      get instruments_path
    end

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Unable to load instruments from MOEX")
  end

  it "renders candlestick chart for known instrument" do
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

    expect(response).to have_http_status(:success)
    expect(response.body).to include("USDRUBF")
    expect(response.body).to include("price-chart")
    expect(response.body).to include("price-chart-candles-value")
    expect(response.body).to include("79.19")
    expect(response.body).to include("Price chart")
    expect(response.body).to include("TradingView")
    expect(response.body).not_to include("<table")
  end

  it "redirects for unknown instrument" do
    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [] }) do
      get instrument_path("UNKNOWN")
    end

    expect(response).to redirect_to(instruments_path)
    expect(flash[:alert]).to eq("Instrument UNKNOWN not found.")
  end

  it "redirects when MOEX candles request fails" do
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

    expect(response).to redirect_to(instruments_path)
    expect(flash[:alert]).to match(/Unable to load chart data from MOEX/)
  end

  it "accepts custom date range query params" do
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )
    captured = {}

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      with_stubbed_class_method(Moex::CurrencyFutures::HistoricalCandles, :call, ->(**kwargs) {
        captured.merge!(kwargs)
        []
      }) do
        get instrument_path("USDRUBF"), params: { from: "2025-06-01", till: "2025-06-15" }
      end
    end

    expect(response).to have_http_status(:success)
    expect(captured[:from]).to eq(Date.new(2025, 6, 1))
    expect(captured[:till]).to eq(Date.new(2025, 6, 15))
  end

  it "ignores invalid date params and uses defaults" do
    instrument = Moex::CurrencyFutures::List::Instrument.new(
      secid: "USDRUBF",
      shortname: "USDRUBF",
      asset_code: "USDRUBTOM"
    )
    captured = {}

    with_stubbed_class_method(Moex::CurrencyFutures::List, :call, ->(**) { [ instrument ] }) do
      with_stubbed_class_method(Moex::CurrencyFutures::HistoricalCandles, :call, ->(**kwargs) {
        captured.merge!(kwargs)
        []
      }) do
        get instrument_path("USDRUBF"), params: { from: "not-a-date", till: "also-bad" }
      end
    end

    expect(response).to have_http_status(:success)
    expect(captured[:till]).to eq(Date.current)
    expect(captured[:from]).to eq(Date.current - InstrumentsController::DEFAULT_RANGE_DAYS.days)
  end
end
