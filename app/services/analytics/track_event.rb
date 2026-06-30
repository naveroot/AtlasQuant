require "net/http"
require "json"

module Analytics
  class TrackEvent
    SIGNUP = "signup"
    ADD_TO_WATCHLIST = "add_to_watchlist"
    VIEW_INSTRUMENT = "view_instrument"
    VIEW_BASIS = "view_basis"

    Result = Data.define(:success, :skipped)

    class << self
      def enabled?
        api_key.present?
      end

      def call(event:, distinct_id:, properties: {})
        return Result.new(success: true, skipped: true) unless enabled?

        payload = {
          api_key: api_key,
          event: event,
          distinct_id: distinct_id.to_s,
          properties: properties.merge("$lib" => "atlas_quant_rails")
        }

        uri = URI("#{host}/capture/")
        response = Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json")

        Result.new(success: response.is_a?(Net::HTTPSuccess), skipped: false)
      end

      def track_signup(user:)
        call(event: SIGNUP, distinct_id: user.id)
      end

      def track_add_to_watchlist(user:, secid:)
        call(event: ADD_TO_WATCHLIST, distinct_id: user.id, properties: { secid: secid })
      end

      private

      def api_key
        ENV["POSTHOG_API_KEY"]
      end

      def host
        ENV.fetch("POSTHOG_HOST", "https://us.i.posthog.com").chomp("/")
      end
    end
  end
end
