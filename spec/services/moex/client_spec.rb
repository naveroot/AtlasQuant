require "rails_helper"

RSpec.describe Moex::Client do
  describe "#parse_table_response" do
    it "parses ISS table response into row hashes" do
      payload = {
        "securities" => {
          "columns" => %w[SECID SHORTNAME ASSETCODE],
          "data" => [
            [ "USDRUBF", "USDRUBF", "USDRUBTOM" ],
            [ "SiU6", "Si-9.26", "Si" ]
          ]
        }
      }

      client = described_class.new
      tables = client.send(:parse_table_response, payload)

      expect(tables[:securities].size).to eq(2)
      expect(tables[:securities].first["SECID"]).to eq("USDRUBF")
      expect(tables[:securities].last["ASSETCODE"]).to eq("Si")
    end
  end

  describe "#get" do
    it "raises error on HTTP failure" do
      client = described_class.new
      response = Object.new
      response.define_singleton_method(:code) { "503" }
      response.define_singleton_method(:is_a?) { |klass| klass == Net::HTTPSuccess ? false : super(klass) }

      with_stubbed_instance_method(client, :perform_request, ->(_uri) { response }) do
        expect {
          client.get("/engines/futures/markets/forts/securities.json")
        }.to raise_error(Moex::Client::Error, /HTTP 503/)
      end
    end
  end

  describe "#perform_request" do
    it "raises error on network timeout" do
      client = described_class.new
      uri = URI.parse("https://iss.moex.com/iss/engines/futures/markets/forts/securities.json")

      with_stubbed_class_method(Net::HTTP, :start, ->(*) { raise Net::ReadTimeout }) do
        expect {
          client.send(:perform_request, uri)
        }.to raise_error(Moex::Client::Error, /MOEX ISS request failed/)
      end
    end
  end
end
