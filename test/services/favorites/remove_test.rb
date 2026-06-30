require "test_helper"

module Favorites
  class RemoveTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
    end

    test "removes favorite instrument" do
      assert_difference -> { @user.favorite_instruments.count }, -1 do
        result = Remove.call(user: @user, secid: favorite_instruments(:one).secid)

        assert result.success?
      end
    end

    test "returns error when favorite does not exist" do
      result = Remove.call(user: @user, secid: "UNKNOWN")

      assert_not result.success?
      assert_match "not in favorites", result.error
    end
  end
end
