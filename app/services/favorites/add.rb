module Favorites
  class Add
    Result = Data.define(:success?, :favorite, :error)

    def self.call(user:, secid:)
      new(user:, secid:).call
    end

    def initialize(user:, secid:)
      @user = user
      @secid = secid
    end

    def call
      instrument = find_instrument
      return Result.new(success?: false, favorite: nil, error: "Instrument #{@secid} not found.") unless instrument

      favorite = @user.favorite_instruments.find_or_create_by!(secid: instrument.secid) do |record|
        record.shortname = instrument.shortname
        record.asset_code = instrument.asset_code
      end

      Result.new(success?: true, favorite:, error: nil)
    rescue Moex::Client::Error => e
      Result.new(success?: false, favorite: nil, error: "Unable to load instruments from MOEX: #{e.message}")
    end

    private

    def find_instrument
      Moex::CurrencyFutures::List.call.find { |entry| entry.secid == @secid }
    end
  end
end
