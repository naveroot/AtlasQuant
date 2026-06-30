import posthog from "posthog-js"

let initialized = false

export function initPosthog({ apiKey, host, userId }) {
  if (!apiKey || initialized) return null

  posthog.init(apiKey, {
    api_host: host || "https://us.i.posthog.com",
    capture_pageview: false,
    persistence: "localStorage"
  })

  if (userId) {
    posthog.identify(String(userId))
  }

  initialized = true
  return posthog
}

export function trackEvent(name, properties = {}) {
  if (!initialized) return

  posthog.capture(name, properties)
}
