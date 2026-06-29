module Moex
  module CurrencyFutures
    class List
      CURRENCY_ASSET_CODES = %w[Si Eu Cn ED USDRUBTOM EURRUBTOM CNYRUBTOM].freeze
      CACHE_KEY = "moex/currency_futures/list".freeze
      CACHE_TTL = 15.minutes

      Instrument = Data.define(:secid, :shortname, :asset_code)

      def self.call(client: Client.new)
        new(client:).call
      end

      def initialize(client:)
        @client = client
      end

      def call
        Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
          rows = @client.get("/engines/futures/markets/forts/securities.json")[:securities]

          rows.filter_map do |row|
            asset_code = row["ASSETCODE"]
            next unless CURRENCY_ASSET_CODES.include?(asset_code)

            Instrument.new(
              secid: row["SECID"],
              shortname: row["SHORTNAME"],
              asset_code:
            )
          end.sort_by(&:secid)
        end
      end
    end
  end
end
