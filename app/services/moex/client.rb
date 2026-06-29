require "net/http"
require "json"
require "uri"

module Moex
  class Client
    class Error < StandardError; end

    BASE_URL = "https://iss.moex.com/iss".freeze
    DEFAULT_TIMEOUT = 10

    def initialize(base_url: BASE_URL, timeout: DEFAULT_TIMEOUT)
      @base_url = base_url
      @timeout = timeout
    end

    def get(path, params: {})
      uri = build_uri(path, params)
      response = perform_request(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "MOEX ISS request failed with HTTP #{response.code}"
      end

      parse_table_response(JSON.parse(response.body))
    end

    private

    def build_uri(path, params)
      query = params.merge("iss.meta" => "off").compact
      uri = URI.parse("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(query)
      uri
    end

    def perform_request(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: @timeout, read_timeout: @timeout) do |http|
        http.get(uri.request_uri)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      raise Error, "MOEX ISS request failed: #{e.message}"
    end

    def parse_table_response(payload)
      payload.each_with_object({}) do |(table_name, table_payload), memo|
        next unless table_payload.is_a?(Hash) && table_payload["columns"].is_a?(Array)

        columns = table_payload["columns"]
        memo[table_name.to_sym] = table_payload["data"].map do |row|
          columns.zip(row).to_h
        end
      end
    end
  end
end
