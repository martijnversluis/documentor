import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button"]
  static values = { maxHeight: { type: Number, default: 48 } }

  connect() {
    this.checkOverflow()
  }

  checkOverflow() {
    const content = this.contentTarget
    const scrollHeight = content.scrollHeight
    const maxHeight = this.maxHeightValue

    if (scrollHeight > maxHeight + 10) {
      content.style.maxHeight = `${maxHeight}px`
      content.classList.add("overflow-hidden")
      this.buttonTarget.classList.remove("hidden")
      this.expanded = false
    } else {
      this.buttonTarget.classList.add("hidden")
    }
  }

  toggle() {
    const content = this.contentTarget

    if (this.expanded) {
      content.style.maxHeight = `${this.maxHeightValue}px`
      this.buttonTarget.textContent = "Meer"
      this.expanded = false
    } else {
      content.style.maxHeight = `${content.scrollHeight}px`
      this.buttonTarget.textContent = "Minder"
      this.expanded = true
    }
  }
}
