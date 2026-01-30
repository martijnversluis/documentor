import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "button"]
  static classes = ["expanded"]

  toggle() {
    this.containerTarget.classList.toggle("max-w-4xl")
    this.containerTarget.classList.toggle("max-w-full")
    this.expanded = !this.expanded
    this.updateButton()
  }

  updateButton() {
    const expandIcon = this.buttonTarget.querySelector(".expand-icon")
    const collapseIcon = this.buttonTarget.querySelector(".collapse-icon")

    if (this.expanded) {
      expandIcon?.classList.add("hidden")
      collapseIcon?.classList.remove("hidden")
    } else {
      expandIcon?.classList.remove("hidden")
      collapseIcon?.classList.add("hidden")
    }
  }

  get expanded() {
    return this._expanded || false
  }

  set expanded(value) {
    this._expanded = value
  }
}
