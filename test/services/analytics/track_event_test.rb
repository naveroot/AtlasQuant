require "test_helper"

class Analytics::TrackEventTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "analytics@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @original_api_key = ENV["POSTHOG_API_KEY"]
    @original_host = ENV["POSTHOG_HOST"]
  end

  teardown do
    ENV["POSTHOG_API_KEY"] = @original_api_key
    ENV["POSTHOG_HOST"] = @original_host
  end

  test "enabled? is false without POSTHOG_API_KEY" do
    ENV["POSTHOG_API_KEY"] = nil

    assert_not Analytics::TrackEvent.enabled?
  end

  test "call is no-op without POSTHOG_API_KEY" do
    ENV["POSTHOG_API_KEY"] = nil

    result = Analytics::TrackEvent.track_signup(user: @user)

    assert result.skipped
    assert result.success
  end

  test "track_signup posts signup event to PostHog capture API" do
    ENV["POSTHOG_API_KEY"] = "phc_test_key"
    ENV["POSTHOG_HOST"] = "https://us.i.posthog.com"
    captured = nil
    original_post = Net::HTTP.method(:post)

    Net::HTTP.define_singleton_method(:post) do |uri, body, _headers|
      captured = JSON.parse(body)
      Net::HTTPSuccess.new("1.1", "200", "OK")
    end

    result = Analytics::TrackEvent.track_signup(user: @user)

    assert result.success
    assert_not result.skipped
    assert_equal "phc_test_key", captured["api_key"]
    assert_equal "signup", captured["event"]
    assert_equal @user.id.to_s, captured["distinct_id"]
  ensure
    Net::HTTP.define_singleton_method(:post, original_post)
  end

  test "track_add_to_watchlist posts event with secid property" do
    ENV["POSTHOG_API_KEY"] = "phc_test_key"
    captured = nil
    original_post = Net::HTTP.method(:post)

    Net::HTTP.define_singleton_method(:post) do |uri, body, _headers|
      captured = JSON.parse(body)
      Net::HTTPSuccess.new("1.1", "200", "OK")
    end

    Analytics::TrackEvent.track_add_to_watchlist(user: @user, secid: "SiM5")

    assert_equal "add_to_watchlist", captured["event"]
    assert_equal "SiM5", captured["properties"]["secid"]
    assert_equal @user.id.to_s, captured["distinct_id"]
  ensure
    Net::HTTP.define_singleton_method(:post, original_post)
  end
end
