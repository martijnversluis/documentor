import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "wrapper", "destroy"]
  static values = { wrapperClass: String }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(`.${this.wrapperClassValue}`) || event.target.closest("[data-nested-form-target='wrapper']")

    if (wrapper) {
      // If this is a persisted record, mark for destruction
      const destroyInput = wrapper.querySelector("[data-nested-form-target='destroy']")
      if (destroyInput && destroyInput.value !== "") {
        destroyInput.value = "1"
        wrapper.style.display = "none"
      } else {
        // If it's a new record, just remove it
        wrapper.remove()
      }
    }
  }
}
