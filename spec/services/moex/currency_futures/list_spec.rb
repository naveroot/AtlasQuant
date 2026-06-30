require "rails_helper"

RSpec.describe Moex::CurrencyFutures::List do
  before { Rails.cache.clear }

  def fake_client(securities:)
    client = Object.new
    client.define_singleton_method(:get) { |_path, params: {}| { securities: } }
    client
  end

  it "returns only currency futures instruments" do
    client = fake_client(
      securities: [
        { "SECID" => "USDRUBF", "SHORTNAME" => "USDRUBF", "ASSETCODE" => "USDRUBTOM" },
        { "SECID" => "SiU6", "SHORTNAME" => "Si-9.26", "ASSETCODE" => "Si" },
        { "SECID" => "BRU6", "SHORTNAME" => "BR-9.26", "ASSETCODE" => "BR" }
      ]
    )

    instruments = described_class.call(client:)

    expect(instruments.size).to eq(2)
    expect(instruments.map(&:secid)).to eq(%w[SiU6 USDRUBF])
    expect(instruments.first.asset_code).to eq("Si")
  end

  it "caches list response" do
    calls = 0
    client = Object.new
    client.define_singleton_method(:get) do |_path, params: {}|
      calls += 1
      { securities: [ { "SECID" => "USDRUBF", "SHORTNAME" => "USDRUBF", "ASSETCODE" => "USDRUBTOM" } ] }
    end

    with_memory_cache do
      described_class.call(client:)
      described_class.call(client:)
    end

    expect(calls).to eq(1)
  end
end
