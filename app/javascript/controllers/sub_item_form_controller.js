import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { parentId: Number }

  toggle() {
    const formDiv = document.getElementById(`sub-item-form-${this.parentIdValue}`)
    if (formDiv) {
      formDiv.classList.toggle("hidden")
      if (!formDiv.classList.contains("hidden")) {
        const input = formDiv.querySelector("input[type='text']")
        if (input) input.focus()
      }
    }
  }
}
