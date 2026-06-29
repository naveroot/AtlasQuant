module Favorites
  class Add
    Result = Data.define(:success?, :favorite, :errors)

    def self.call(user:, secid:)
      new(user:, secid:).call
    end

    def initialize(user:, secid:)
      @user = user
      @secid = secid.to_s.strip
    end

    def call
      unless valid_secid?
        return failure(:secid, "is not a valid MOEX instrument")
      end

      favorite = @user.favorites.build(secid: @secid)

      if favorite.save
        Result.new(success?: true, favorite:, errors: nil)
      else
        Result.new(success?: false, favorite:, errors: favorite.errors)
      end
    end

    private

    def valid_secid?
      Moex::CurrencyFutures::List.call.any? { |instrument| instrument.secid == @secid }
    end

    def failure(attribute, message)
      errors = ActiveModel::Errors.new(Favorite.new)
      errors.add(attribute, message)
      Result.new(success?: false, favorite: nil, errors:)
    end
  end
end
