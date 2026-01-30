import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["daysContainer"]
  static values = { frequency: String }

  connect() {
    this.updateVisibility()

    // Listen for changes on the frequency select
    const frequencySelect = this.element.closest("form")?.querySelector("select[name='habit[frequency]']")
    if (frequencySelect) {
      frequencySelect.addEventListener("change", (e) => {
        this.frequencyValue = e.target.value
        this.updateVisibility()
      })
    }
  }

  updateVisibility() {
    if (this.hasDaysContainerTarget) {
      if (this.frequencyValue === "weekly") {
        this.daysContainerTarget.classList.remove("hidden")
      } else {
        this.daysContainerTarget.classList.add("hidden")
      }
    }
  }
}
