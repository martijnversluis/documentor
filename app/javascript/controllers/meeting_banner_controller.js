import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 15000 } // Poll every 15 seconds
  }

  connect() {
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    // Initial fetch after a short delay
    this.pollTimer = setTimeout(() => {
      this.fetchBanner()
      // Then set up recurring polls
      this.pollTimer = setInterval(() => this.fetchBanner(), this.intervalValue)
    }, 5000) // Wait 5 seconds before first poll
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      clearTimeout(this.pollTimer)
    }
  }

  async fetchBanner() {
    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        // Turbo will automatically process the stream
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Failed to fetch meeting banner:", error)
    }
  }
}
