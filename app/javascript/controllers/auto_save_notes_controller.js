import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notes", "status", "display"]
  static values = {
    url: String,
    param: { type: String, default: "notes" },
    delay: { type: Number, default: 1500 }
  }

  connect() {
    this.saveTimer = null
    this.lastSavedNotes = this.hasNotesTarget ? this.notesTarget.value : ""
  }

  disconnect() {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
      this.saveNotes()
    }
  }

  edit() {
    if (this.hasDisplayTarget && this.hasNotesTarget) {
      // Get the height of the rendered content before hiding
      const displayHeight = this.displayTarget.offsetHeight
      const minHeight = Math.max(displayHeight, 100) // At least 100px

      this.displayTarget.classList.add("hidden")
      this.notesTarget.classList.remove("hidden")

      // Set textarea height to match the display content
      this.notesTarget.style.height = `${minHeight}px`

      this.notesTarget.focus()
      // Move cursor to end
      this.notesTarget.setSelectionRange(this.notesTarget.value.length, this.notesTarget.value.length)
    }
  }

  autoResize() {
    if (this.hasNotesTarget) {
      this.notesTarget.style.height = "auto"
      this.notesTarget.style.height = `${this.notesTarget.scrollHeight}px`
    }
  }

  blur() {
    // Save immediately on blur
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
    }
    this.saveNotesAndUpdateDisplay()
  }

  async saveNotesAndUpdateDisplay() {
    if (!this.hasNotesTarget || !this.hasDisplayTarget) return

    const currentNotes = this.notesTarget.value

    if (currentNotes !== this.lastSavedNotes) {
      this.updateStatus("Opslaan...")
      try {
        const response = await fetch(this.urlValue, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "text/plain",
            "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
          },
          body: `${this.paramValue}=${encodeURIComponent(currentNotes)}`
        })

        if (response.ok) {
          this.lastSavedNotes = currentNotes
          const html = await response.text()

          if (currentNotes.trim()) {
            this.displayTarget.innerHTML = html
            this.displayTarget.classList.remove("text-gray-400")
            this.displayTarget.classList.add("text-gray-700")
          } else {
            this.displayTarget.innerHTML = '<p class="italic">Klik om notities toe te voegen...</p>'
            this.displayTarget.classList.add("text-gray-400")
            this.displayTarget.classList.remove("text-gray-700")
          }
          this.updateStatus("")
        }
      } catch (error) {
        console.error("Failed to save notes:", error)
        this.updateStatus("Opslaan mislukt")
      }
    } else {
      // No changes, just update display and clear status
      this.updateStatus("")
      if (!currentNotes.trim()) {
        this.displayTarget.innerHTML = '<p class="italic">Klik om notities toe te voegen...</p>'
        this.displayTarget.classList.add("text-gray-400")
        this.displayTarget.classList.remove("text-gray-700")
      }
    }

    this.displayTarget.classList.remove("hidden")
    this.notesTarget.classList.add("hidden")
  }

  scheduleAutoSave() {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
    }

    this.updateStatus("Opslaan...")

    this.saveTimer = setTimeout(() => {
      this.saveNotes()
    }, this.delayValue)
  }

  async saveNotes() {
    if (!this.hasNotesTarget) return

    const currentNotes = this.notesTarget.value
    if (currentNotes === this.lastSavedNotes) {
      this.updateStatus("")
      return
    }

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: `${this.paramValue}=${encodeURIComponent(currentNotes)}`
      })

      if (response.ok) {
        this.lastSavedNotes = currentNotes
        this.updateStatus("Opgeslagen")
        setTimeout(() => this.updateStatus(""), 2000)
      }
    } catch (error) {
      console.error("Failed to save notes:", error)
      this.updateStatus("Opslaan mislukt")
    }
  }

  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }
}
