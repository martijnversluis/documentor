import { Controller } from "@hotwired/stimulus"

// Handles interactive checkboxes in markdown content
// Usage: Add data-controller="markdown-checkbox" to the container
//        with data-markdown-checkbox-url-value="/path/to/update"
//        and data-markdown-checkbox-field-value="description"
export default class extends Controller {
  static values = {
    url: String,
    field: String
  }

  toggle(event) {
    const checkbox = event.target
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    const index = Array.from(checkboxes).indexOf(checkbox)

    if (index === -1) return

    const checked = checkbox.checked

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        checkbox_index: index,
        checked: checked,
        field: this.fieldValue
      })
    }).then(response => {
      if (!response.ok) {
        // Revert checkbox state on error
        checkbox.checked = !checked
      }
    }).catch(() => {
      checkbox.checked = !checked
    })
  }
}
