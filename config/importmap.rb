# Pin npm packages by running ./bin/importmap

pin "application"
pin "posthog-js", to: "https://cdn.jsdelivr.net/npm/posthog-js@1.256.1/dist/module.js"
pin_all_from "app/javascript/analytics", under: "analytics"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "lightweight-charts", to: "https://cdn.jsdelivr.net/npm/lightweight-charts@5.0.7/dist/lightweight-charts.standalone.production.mjs"
pin_all_from "app/javascript/controllers", under: "controllers"
