import { Controller } from "@hotwired/stimulus"
import { initPosthog, trackEvent } from "analytics/posthog_client"

export default class extends Controller {
  static values = {
    apiKey: String,
    host: { type: String, default: "https://us.i.posthog.com" },
    userId: String,
    events: { type: Array, default: [] }
  }

  connect() {
    initPosthog({
      apiKey: this.apiKeyValue,
      host: this.hostValue,
      userId: this.hasUserIdValue ? this.userIdValue : null
    })

    this.eventsValue.forEach(({ event, properties }) => {
      trackEvent(event, properties || {})
    })
  }
}
