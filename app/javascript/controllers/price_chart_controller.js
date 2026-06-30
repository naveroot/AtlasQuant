import { Controller } from "@hotwired/stimulus"
import { createChart, CandlestickSeries } from "lightweight-charts"

export default class extends Controller {
  static values = {
    candles: Array
  }

  static targets = ["container"]

  connect() {
    this.chart = createChart(this.containerTarget, {
      layout: {
        background: { color: "#ffffff" },
        textColor: "#374151"
      },
      grid: {
        vertLines: { color: "#f3f4f6" },
        horzLines: { color: "#f3f4f6" }
      },
      crosshair: {
        mode: 1
      },
      rightPriceScale: {
        borderColor: "#e5e7eb"
      },
      timeScale: {
        borderColor: "#e5e7eb",
        timeVisible: false
      }
    })

    this.series = this.chart.addSeries(CandlestickSeries, {
      upColor: "#16a34a",
      downColor: "#dc2626",
      borderUpColor: "#16a34a",
      borderDownColor: "#dc2626",
      wickUpColor: "#16a34a",
      wickDownColor: "#dc2626"
    })

    this.series.setData(this.candlesValue)
    this.chart.timeScale().fitContent()
    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.containerTarget)
    this.resize()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.chart?.remove()
  }

  resize() {
    const { width, height } = this.containerTarget.getBoundingClientRect()
    if (width > 0 && height > 0) {
      this.chart.applyOptions({ width, height })
    }
  }
}
