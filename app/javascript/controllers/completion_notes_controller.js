import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notes", "display"]
  static values = {
    url: String,
    delay: { type: Number, default: 1000 }
  }

  connect() {
    this.saveTimer = null
    this.lastSavedNotes = this.hasNotesTarget ? this.notesTarget.value : ""
    this.updateDisplay()
  }

  disconnect() {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
      this.save()
    }
  }

  updateDisplay() {
    if (!this.hasDisplayTarget || !this.hasNotesTarget) return
    const hasContent = this.notesTarget.value.trim().length > 0
    this.displayTarget.classList.toggle("hidden", !hasContent)
    this.notesTarget.classList.toggle("hidden", hasContent)
  }

  edit() {
    if (!this.hasDisplayTarget || !this.hasNotesTarget) return
    this.displayTarget.classList.add("hidden")
    this.notesTarget.classList.remove("hidden")
    this.notesTarget.style.height = "auto"
    this.notesTarget.style.height = Math.max(this.notesTarget.scrollHeight, 60) + "px"
    this.notesTarget.focus()
  }

  blur() {
    if (!this.hasNotesTarget) return
    // Small delay to allow click events to fire first
    setTimeout(() => {
      this.updateDisplay()
    }, 100)
  }

  resize() {
    if (!this.hasNotesTarget) return
    const textarea = this.notesTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.max(textarea.scrollHeight, 60) + "px"
  }

  scheduleAutoSave() {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
    }

    this.resize()

    this.saveTimer = setTimeout(() => {
      this.save()
    }, this.delayValue)
  }

  async save() {
    if (!this.hasNotesTarget || !this.urlValue) return

    const currentNotes = this.notesTarget.value
    if (currentNotes === this.lastSavedNotes) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "text/html"
        },
        body: JSON.stringify({ notes: currentNotes })
      })
      this.lastSavedNotes = currentNotes

      // Update the rendered markdown display
      if (this.hasDisplayTarget && response.ok) {
        const html = await response.text()
        if (html.trim()) {
          this.displayTarget.innerHTML = html
        }
      }
    } catch (error) {
      console.error("Auto-save failed:", error)
    }
  }
}
