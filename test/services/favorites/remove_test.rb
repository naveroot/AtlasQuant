require "test_helper"

class Favorites::RemoveTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "removes existing favorite" do
    secid = favorites(:one_usdrubf).secid

    assert_difference -> { @user.favorites.count }, -1 do
      result = Favorites::Remove.call(user: @user, secid:)
      assert result.success?
    end
  end

  test "returns error when favorite missing" do
    result = Favorites::Remove.call(user: @user, secid: "MISSING")

    assert_not result.success?
    assert_includes result.errors.full_messages.join, "not in favorites"
  end
end
