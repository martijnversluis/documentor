import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "spinner"]
  static values = {
    url: String
  }

  connect() {
    this.load()
  }

  refresh() {
    // Add spinning animation to refresh button
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("animate-spin")
    }
    this.load(true)
  }

  async load(forceRefresh = false) {
    try {
      let url = this.urlValue
      if (forceRefresh) {
        url += (url.includes("?") ? "&" : "?") + "refresh=1"
      }

      const response = await fetch(url, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      // Stop spinning
      if (this.hasSpinnerTarget) {
        this.spinnerTarget.classList.remove("animate-spin")
      }

      const target = this.hasContentTarget ? this.contentTarget : this.element

      if (response.ok) {
        const html = await response.text()
        target.innerHTML = html
      } else {
        target.innerHTML = '<div class="text-center py-4 text-red-500 text-sm">Kon data niet laden</div>'
      }
    } catch (error) {
      console.error("Lazy load error:", error)
      if (this.hasSpinnerTarget) {
        this.spinnerTarget.classList.remove("animate-spin")
      }
      const target = this.hasContentTarget ? this.contentTarget : this.element
      target.innerHTML = '<div class="text-center py-4 text-red-500 text-sm">Kon data niet laden</div>'
    }
  }
}
