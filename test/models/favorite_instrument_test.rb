require "test_helper"

class FavoriteInstrumentTest < ActiveSupport::TestCase
  test "valid favorite instrument" do
    favorite = FavoriteInstrument.new(
      user: users(:one),
      secid: "SiU6",
      shortname: "Si-6.26",
      asset_code: "Si"
    )

    assert favorite.valid?
  end

  test "requires secid shortname and asset_code" do
    favorite = FavoriteInstrument.new(user: users(:one))

    assert_not favorite.valid?
    assert_includes favorite.errors[:secid], "can't be blank"
    assert_includes favorite.errors[:shortname], "can't be blank"
    assert_includes favorite.errors[:asset_code], "can't be blank"
  end

  test "secid is unique per user" do
    duplicate = FavoriteInstrument.new(
      user: users(:one),
      secid: favorite_instruments(:one).secid,
      shortname: "duplicate",
      asset_code: "Si"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:secid], "has already been taken"
  end

  test "same secid allowed for different users" do
    duplicate = FavoriteInstrument.new(
      user: users(:two),
      secid: favorite_instruments(:one).secid,
      shortname: favorite_instruments(:one).shortname,
      asset_code: favorite_instruments(:one).asset_code
    )

    assert duplicate.valid?
  end
end
