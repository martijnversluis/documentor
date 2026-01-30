import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notes", "status", "display"]
  static values = {
    url: String,
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
      this.displayTarget.classList.add("hidden")
      this.notesTarget.classList.remove("hidden")
      this.autoResize()
      this.notesTarget.focus()
    }
  }

  autoResize() {
    if (!this.hasNotesTarget) return
    // Reset height to auto to get the correct scrollHeight
    this.notesTarget.style.height = "auto"
    // Set minimum height and match content
    const minHeight = 60
    this.notesTarget.style.height = Math.max(minHeight, this.notesTarget.scrollHeight) + "px"
  }

  input() {
    this.autoResize()
    this.scheduleAutoSave()
  }

  blur() {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
    }
    this.saveNotesAndUpdateDisplay()
  }

  async saveNotesAndUpdateDisplay() {
    if (!this.hasNotesTarget) return

    const currentNotes = this.notesTarget.value

    if (currentNotes !== this.lastSavedNotes) {
      this.updateStatus("Opslaan...")
      try {
        const response = await fetch(this.urlValue, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
          },
          body: `notes=${encodeURIComponent(currentNotes)}`
        })

        if (response.ok) {
          this.lastSavedNotes = currentNotes
          const html = await response.text()

          if (this.hasDisplayTarget) {
            if (currentNotes.trim()) {
              this.displayTarget.innerHTML = html
              this.displayTarget.classList.remove("text-gray-400", "italic")
            } else {
              this.displayTarget.innerHTML = '<span class="italic">Klik om notities toe te voegen...</span>'
              this.displayTarget.classList.add("text-gray-400")
            }
          }
          this.updateStatus("")
        }
      } catch (error) {
        console.error("Failed to save notes:", error)
        this.updateStatus("Opslaan mislukt")
      }
    } else {
      this.updateStatus("")
    }

    if (this.hasDisplayTarget && this.hasNotesTarget) {
      this.displayTarget.classList.remove("hidden")
      this.notesTarget.classList.add("hidden")
    }
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
        body: `notes=${encodeURIComponent(currentNotes)}`
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
