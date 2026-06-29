require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  test "valid favorite" do
    favorite = Favorite.new(user: users(:one), secid: "CNYRUBF")

    assert favorite.valid?
  end

  test "requires secid" do
    favorite = Favorite.new(user: users(:one), secid: nil)

    assert_not favorite.valid?
    assert_includes favorite.errors[:secid], "can't be blank"
  end

  test "requires unique secid per user" do
    duplicate = Favorite.new(user: users(:one), secid: favorites(:one_usdrubf).secid)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:secid], "has already been taken"
  end

  test "allows same secid for different users" do
    favorite = Favorite.new(user: users(:two), secid: favorites(:one_usdrubf).secid)

    assert favorite.valid?
  end
end
