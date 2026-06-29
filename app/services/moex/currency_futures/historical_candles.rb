module Moex
  module CurrencyFutures
    class HistoricalCandles
      DAILY_INTERVAL = 24
      CACHE_TTL = 15.minutes

      Candle = Data.define(:traded_at, :open, :high, :low, :close, :volume)

      def self.call(secid:, from:, till:, client: Client.new)
        new(secid:, from:, till:, client:).call
      end

      def initialize(secid:, from:, till:, client:)
        @secid = secid
        @from = from
        @till = till
        @client = client
      end

      def call
        cache_key = "moex/currency_futures/candles/#{@secid}/#{@from}/#{@till}"

        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          rows = @client.get(
            "/engines/futures/markets/forts/securities/#{@secid}/candles.json",
            params: {
              from: @from.iso8601,
              till: @till.iso8601,
              interval: DAILY_INTERVAL
            }
          )[:candles]

          Array(rows).map do |row|
            Candle.new(
              traded_at: Time.zone.parse(row["begin"]),
              open: row["open"].to_d,
              high: row["high"].to_d,
              low: row["low"].to_d,
              close: row["close"].to_d,
              volume: row["volume"].to_i
            )
          end
        end
      end
    end
  end
end
