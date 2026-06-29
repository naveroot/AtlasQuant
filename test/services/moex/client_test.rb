require "test_helper"

class Moex::ClientTest < ActiveSupport::TestCase
  test "parses ISS table response into row hashes" do
    payload = {
      "securities" => {
        "columns" => %w[SECID SHORTNAME ASSETCODE],
        "data" => [
          [ "USDRUBF", "USDRUBF", "USDRUBTOM" ],
          [ "SiU6", "Si-9.26", "Si" ]
        ]
      }
    }

    client = Moex::Client.new
    tables = client.send(:parse_table_response, payload)

    assert_equal 2, tables[:securities].size
    assert_equal "USDRUBF", tables[:securities].first["SECID"]
    assert_equal "Si", tables[:securities].last["ASSETCODE"]
  end

  test "raises error on HTTP failure" do
    client = Moex::Client.new
    response = Object.new
    response.define_singleton_method(:code) { "503" }
    response.define_singleton_method(:is_a?) { |klass| klass == Net::HTTPSuccess ? false : super(klass) }

    with_stubbed_instance_method(client, :perform_request, ->(_uri) { response }) do
      error = assert_raises(Moex::Client::Error) do
        client.get("/engines/futures/markets/forts/securities.json")
      end

      assert_match(/HTTP 503/, error.message)
    end
  end

  test "raises error on network timeout" do
    client = Moex::Client.new
    uri = URI.parse("https://iss.moex.com/iss/engines/futures/markets/forts/securities.json")

    with_stubbed_class_method(Net::HTTP, :start, ->(*) { raise Net::ReadTimeout }) do
      error = assert_raises(Moex::Client::Error) do
        client.send(:perform_request, uri)
      end

      assert_match(/MOEX ISS request failed/, error.message)
    end
  end

  private

  def with_stubbed_instance_method(object, method_name, implementation)
    original = object.method(method_name)
    object.define_singleton_method(method_name, &implementation)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end
end
