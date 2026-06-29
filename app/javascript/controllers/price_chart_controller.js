import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static values = {
    labels: Array,
    values: Array
  }

  connect() {
    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: "Close",
            data: this.valuesValue,
            borderColor: "rgb(37, 99, 235)",
            backgroundColor: "rgba(37, 99, 235, 0.1)",
            tension: 0.2,
            fill: true,
            pointRadius: 2
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            ticks: { maxTicksLimit: 10 }
          },
          y: {
            ticks: {
              callback: (value) => value.toLocaleString()
            }
          }
        },
        plugins: {
          legend: { display: false }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
