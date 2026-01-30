import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  reset(event) {
    if (event.detail.success) {
      this.inputTarget.value = ""
      this.inputTarget.focus()

      // Show the action items list and hide empty state
      const list = document.getElementById("inbox-action-items")
      const emptyState = document.getElementById("inbox-empty-state")

      if (list) list.classList.remove("hidden")
      if (emptyState) emptyState.remove()
    }
  }
}
