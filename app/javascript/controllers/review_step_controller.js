import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notes", "hiddenNotes"]
  static values = {
    autoSaveUrl: String,
    autoSaveDelay: { type: Number, default: 2000 }
  }

  connect() {
    this.autoSaveTimer = null
    this.lastSavedNotes = this.hasNotesTarget ? this.notesTarget.value : ""
  }

  disconnect() {
    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer)
      // Save any pending changes before disconnecting
      this.saveNotes()
    }
  }

  syncNotes(event) {
    if (this.hasNotesTarget && this.hasHiddenNotesTarget) {
      this.hiddenNotesTarget.value = this.notesTarget.value
    }
  }

  scheduleAutoSave() {
    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer)
    }

    // Also sync to hidden field
    if (this.hasNotesTarget && this.hasHiddenNotesTarget) {
      this.hiddenNotesTarget.value = this.notesTarget.value
    }

    this.autoSaveTimer = setTimeout(() => {
      this.saveNotes()
    }, this.autoSaveDelayValue)
  }

  async saveNotes() {
    if (!this.hasNotesTarget || !this.autoSaveUrlValue) return

    const currentNotes = this.notesTarget.value
    if (currentNotes === this.lastSavedNotes) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      await fetch(this.autoSaveUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ notes: currentNotes })
      })
      this.lastSavedNotes = currentNotes
    } catch (error) {
      console.error("Auto-save failed:", error)
    }
  }
}
