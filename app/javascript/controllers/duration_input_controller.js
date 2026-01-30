import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["minutes", "seconds", "total"]

  connect() {
    this.updateTotal()

    // Also update on form submit
    const form = this.element.closest("form")
    if (form) {
      form.addEventListener("submit", () => this.updateTotal())
    }
  }

  updateTotal() {
    const minutes = parseInt(this.minutesTarget.value) || 0
    const seconds = parseInt(this.secondsTarget.value) || 0
    const total = (minutes * 60) + seconds

    this.totalTarget.value = total > 0 ? total : ""
  }
}
