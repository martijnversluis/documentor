import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    key: String
  }

  connect() {
    if (this.isDismissed()) {
      this.element.remove()
    }
  }

  dismiss() {
    this.storeDismissal()
    this.element.remove()
  }

  isDismissed() {
    const dismissed = this.getDismissedItems()
    return dismissed.includes(this.keyValue)
  }

  storeDismissal() {
    const dismissed = this.getDismissedItems()
    if (!dismissed.includes(this.keyValue)) {
      dismissed.push(this.keyValue)
      // Clean up old entries (keep only last 50)
      const toStore = dismissed.slice(-50)
      localStorage.setItem("dismissed_banners", JSON.stringify(toStore))
    }
  }

  getDismissedItems() {
    try {
      return JSON.parse(localStorage.getItem("dismissed_banners")) || []
    } catch {
      return []
    }
  }
}
