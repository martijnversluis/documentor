import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["document", "actionItem"]

  connect() {
    this.documentTargets.forEach(doc => {
      doc.addEventListener("dragstart", this.dragStart.bind(this))
      doc.addEventListener("dragend", this.dragEnd.bind(this))
    })
  }

  dragStart(event) {
    const documentId = event.target.dataset.documentId
    event.dataTransfer.setData("text/plain", documentId)
    event.dataTransfer.effectAllowed = "link"
    event.target.classList.add("opacity-50")
  }

  dragEnd(event) {
    event.target.classList.remove("opacity-50")
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "link"
  }

  dragEnter(event) {
    event.preventDefault()
    event.currentTarget.classList.add("bg-blue-50", "border-blue-300")
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("bg-blue-50", "border-blue-300")
  }

  async drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("bg-blue-50", "border-blue-300")

    const documentId = event.dataTransfer.getData("text/plain")
    const actionItemId = event.currentTarget.dataset.actionItemId

    if (!documentId || !actionItemId) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(`/action_items/${actionItemId}/documents`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ document_id: documentId })
      })

      if (response.ok) {
        window.location.reload()
      }
    } catch (error) {
      console.error("Failed to link document:", error)
    }
  }
}
