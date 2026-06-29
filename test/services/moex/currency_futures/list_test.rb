require "test_helper"

class Moex::CurrencyFutures::ListTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "returns only currency futures instruments" do
    client = fake_client(
      securities: [
        { "SECID" => "USDRUBF", "SHORTNAME" => "USDRUBF", "ASSETCODE" => "USDRUBTOM" },
        { "SECID" => "SiU6", "SHORTNAME" => "Si-9.26", "ASSETCODE" => "Si" },
        { "SECID" => "BRU6", "SHORTNAME" => "BR-9.26", "ASSETCODE" => "BR" }
      ]
    )

    instruments = Moex::CurrencyFutures::List.call(client:)

    assert_equal 2, instruments.size
    assert_equal %w[SiU6 USDRUBF], instruments.map(&:secid)
    assert_equal "Si", instruments.first.asset_code
  end

  test "caches list response" do
    calls = 0
    client = Object.new
    client.define_singleton_method(:get) do |_path, params: {}|
      calls += 1
      { securities: [ { "SECID" => "USDRUBF", "SHORTNAME" => "USDRUBF", "ASSETCODE" => "USDRUBTOM" } ] }
    end

    with_memory_cache do
      Moex::CurrencyFutures::List.call(client:)
      Moex::CurrencyFutures::List.call(client:)
    end

    assert_equal 1, calls
  end

  private

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)

    yield
  ensure
    Rails.cache = original_cache
  end

  def fake_client(securities:)
    client = Object.new
    client.define_singleton_method(:get) { |_path, params: {}| { securities: } }
    client
  end
end
