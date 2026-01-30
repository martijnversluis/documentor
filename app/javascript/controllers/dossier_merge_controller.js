import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.draggedItem = null
  }

  dragStart(event) {
    this.draggedItem = event.currentTarget
    this.draggedItem.classList.add("opacity-50")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", event.currentTarget.dataset.dossierId)
  }

  dragEnd(event) {
    if (this.draggedItem) {
      this.draggedItem.classList.remove("opacity-50")
      this.draggedItem = null
    }
    // Remove all drag-over styles
    this.itemTargets.forEach(item => {
      item.classList.remove("ring-2", "ring-blue-500", "ring-offset-2")
    })
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.currentTarget
    const sourceId = event.dataTransfer.getData("text/plain") || this.draggedItem?.dataset.dossierId

    // Don't allow dropping on itself
    if (target.dataset.dossierId === sourceId) {
      return
    }

    target.classList.add("ring-2", "ring-blue-500", "ring-offset-2")
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("ring-2", "ring-blue-500", "ring-offset-2")
  }

  async drop(event) {
    event.preventDefault()

    const target = event.currentTarget
    target.classList.remove("ring-2", "ring-blue-500", "ring-offset-2")

    const sourceId = event.dataTransfer.getData("text/plain")
    const targetId = target.dataset.dossierId

    // Don't allow dropping on itself
    if (sourceId === targetId) {
      return
    }

    // Confirm the merge
    const sourceName = this.draggedItem?.querySelector("p")?.textContent?.trim() || "dit dossier"
    const targetName = target.querySelector("p")?.textContent?.trim() || "het andere dossier"

    if (!confirm(`Weet je zeker dat je "${sourceName}" wilt samenvoegen met "${targetName}"?\n\n${sourceName} wordt een map in ${targetName}.`)) {
      return
    }

    // Perform the merge via PATCH request
    try {
      const response = await fetch(`/dossiers/${sourceId}/merge_into`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ target_id: targetId }),
        redirect: "manual" // Don't follow redirects automatically
      })

      // 200 OK or 302 redirect both mean success
      if (response.ok || response.status === 200 || response.type === "opaqueredirect") {
        window.location.href = "/dossiers"
      } else {
        alert("Er ging iets mis bij het samenvoegen")
      }
    } catch (error) {
      console.error("Merge failed:", error)
      alert("Er ging iets mis bij het samenvoegen")
    }
  }
}
