module Favorites
  class Remove
    Result = Data.define(:success?, :errors)

    def self.call(user:, secid:)
      new(user:, secid:).call
    end

    def initialize(user:, secid:)
      @user = user
      @secid = secid.to_s.strip
    end

    def call
      favorite = @user.favorites.find_by(secid: @secid)

      unless favorite
        errors = ActiveModel::Errors.new(Favorite.new)
        errors.add(:secid, "is not in favorites")
        return Result.new(success?: false, errors:)
      end

      favorite.destroy!
      Result.new(success?: true, errors: nil)
    end
  end
end
