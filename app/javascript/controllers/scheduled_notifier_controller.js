import { Controller } from "@hotwired/stimulus"

const MAX_DELAY_MS = 24 * 60 * 60 * 1000

export default class extends Controller {
  static values = { url: String }

  async connect() {
    this.timers = []

    if (!("Notification" in window)) return

    if (Notification.permission === "default") {
      try { await Notification.requestPermission() } catch (_) {}
    }

    this.scheduleUpcoming()
  }

  disconnect() {
    this.clearTimers()
  }

  clearTimers() {
    (this.timers || []).forEach(t => clearTimeout(t))
    this.timers = []
  }

  async scheduleUpcoming() {
    this.clearTimers()

    let items
    try {
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
      if (!response.ok) return
      items = await response.json()
    } catch (_) {
      return
    }

    const now = Date.now()
    items.forEach(item => {
      const dueAt = Date.parse(item.scheduled_at)
      if (Number.isNaN(dueAt)) return
      const delay = dueAt - now
      if (delay <= 0) return
      if (delay > MAX_DELAY_MS) return

      const timer = setTimeout(() => this.fire(item), delay)
      this.timers.push(timer)
    })
  }

  fire(item) {
    if ("Notification" in window && Notification.permission === "granted") {
      try {
        const notification = new Notification("Actiepunt actief", {
          body: item.description,
          tag: `action-item-${item.id}`,
          requireInteraction: false
        })
        notification.onclick = () => {
          window.focus()
          notification.close()
        }
      } catch (_) {}
    }

    window.dispatchEvent(new CustomEvent("action-items:refresh"))
  }
}
