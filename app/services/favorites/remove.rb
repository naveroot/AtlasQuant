module Favorites
  class Remove
    Result = Data.define(:success?, :error)

    def self.call(user:, secid:)
      new(user:, secid:).call
    end

    def initialize(user:, secid:)
      @user = user
      @secid = secid
    end

    def call
      favorite = @user.favorite_instruments.find_by(secid: @secid)

      unless favorite
        return Result.new(success?: false, error: "Instrument #{@secid} is not in favorites.")
      end

      favorite.destroy!
      Result.new(success?: true, error: nil)
    end
  end
end
