import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    actionItemId: Number
  }

  connect() {
    this.element.addEventListener("dragover", this.dragover.bind(this))
    this.element.addEventListener("dragenter", this.dragenter.bind(this))
    this.element.addEventListener("dragleave", this.dragleave.bind(this))
    this.element.addEventListener("drop", this.drop.bind(this))
  }

  dragover(event) {
    // Only accept document drops
    if (!event.dataTransfer.types.includes("application/document")) return

    event.preventDefault()
    event.dataTransfer.dropEffect = "link"
    this.element.classList.add("bg-blue-50", "ring-2", "ring-blue-400")
  }

  dragenter(event) {
    if (!event.dataTransfer.types.includes("application/document")) return
    event.preventDefault()
  }

  dragleave(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.element.classList.remove("bg-blue-50", "ring-2", "ring-blue-400")
    }
  }

  async drop(event) {
    event.preventDefault()
    event.stopPropagation()

    this.element.classList.remove("bg-blue-50", "ring-2", "ring-blue-400")

    const documentId = event.dataTransfer.getData("application/document")
    if (!documentId) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const url = `/action_items/${this.actionItemIdValue}/documents`

    const formData = new FormData()
    formData.append("document_id", documentId)

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        // Show success feedback
        this.showFeedback("Document gekoppeld")
      } else {
        console.error("Failed to link document to action item")
      }
    } catch (error) {
      console.error("Failed to link document:", error)
    }
  }

  showFeedback(message) {
    const feedback = document.createElement("div")
    feedback.className = "fixed bottom-4 right-4 bg-green-600 text-white px-4 py-2 rounded-lg shadow-lg z-50 animate-fade-in"
    feedback.textContent = message
    document.body.appendChild(feedback)

    setTimeout(() => {
      feedback.remove()
    }, 2000)
  }
}
