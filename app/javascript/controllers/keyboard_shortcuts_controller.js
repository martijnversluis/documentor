import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    nextMeetingUrl: String,
    nextReviewUrl: String,
    todayUrl: String
  }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    // Don't trigger shortcuts when typing in inputs
    if (this.isTyping(event)) return

    // Don't trigger when using modifier keys (except for specific combos)
    if (event.metaKey || event.ctrlKey || event.altKey) return

    switch (event.key.toLowerCase()) {
      case "m":
        event.preventDefault()
        this.joinNextMeeting()
        break
      case "r":
        event.preventDefault()
        this.startNextReview()
        break
      case "a":
        event.preventDefault()
        this.addActionItem()
        break
      case "t":
        event.preventDefault()
        this.goToToday()
        break
      case "w":
        event.preventDefault()
        this.toggleWorkMode()
        break
      case "?":
        event.preventDefault()
        this.showHelp()
        break
      case "escape":
        this.hideHelp()
        break
    }
  }

  isTyping(event) {
    const target = event.target
    const tagName = target.tagName.toLowerCase()
    return (
      tagName === "input" ||
      tagName === "textarea" ||
      tagName === "select" ||
      target.isContentEditable
    )
  }

  async joinNextMeeting() {
    try {
      const response = await fetch(this.nextMeetingUrlValue, {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        const data = await response.json()
        if (data.conference_url) {
          window.open(data.conference_url, "_blank")
        } else {
          this.showNotification("Geen aankomende meeting met video link", "warning")
        }
      }
    } catch (error) {
      console.error("Failed to get next meeting:", error)
    }
  }

  async startNextReview() {
    try {
      const response = await fetch(this.nextReviewUrlValue, {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        const data = await response.json()
        if (data.review_url) {
          window.location.href = data.review_url
        } else {
          this.showNotification("Geen review om te starten", "warning")
        }
      }
    } catch (error) {
      console.error("Failed to get next review:", error)
    }
  }

  addActionItem() {
    // Try to find and focus the action item input on the current page
    const input = document.querySelector('input[name="action_item[description]"]')
    if (input) {
      input.focus()
      input.scrollIntoView({ behavior: "smooth", block: "center" })
    } else {
      // Navigate to action items page
      window.location.href = this.todayUrlValue
    }
  }

  goToToday() {
    window.location.href = this.todayUrlValue
  }

  toggleWorkMode() {
    // Find and click the work mode button in the nav
    const workModeButton = document.querySelector('form[action="/work_mode"] button')
    if (workModeButton) {
      workModeButton.click()
    }
  }

  showHelp() {
    const existingHelp = document.getElementById("keyboard-shortcuts-help")
    if (existingHelp) {
      existingHelp.remove()
      return
    }

    const help = document.createElement("div")
    help.id = "keyboard-shortcuts-help"
    help.className = "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50"
    help.innerHTML = `
      <div class="bg-white rounded-lg shadow-xl p-6 max-w-sm">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Sneltoetsen</h3>
        <dl class="space-y-2 text-sm">
          <div class="flex justify-between">
            <dt class="text-gray-600">Meeting joinen</dt>
            <dd><kbd class="px-2 py-1 bg-gray-100 rounded text-xs font-mono">M</kbd></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-600">Review starten</dt>
            <dd><kbd class="px-2 py-1 bg-gray-100 rounded text-xs font-mono">R</kbd></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-600">Actiepunt toevoegen</dt>
            <dd><kbd class="px-2 py-1 bg-gray-100 rounded text-xs font-mono">A</kbd></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-600">Naar vandaag</dt>
            <dd><kbd class="px-2 py-1 bg-gray-100 rounded text-xs font-mono">T</kbd></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-600">Werkmodus toggle</dt>
            <dd><kbd class="px-2 py-1 bg-gray-100 rounded text-xs font-mono">W</kbd></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-600">Zoeken</dt>
            <dd><kbd class="px-2 py-1 bg-gray-100 rounded text-xs font-mono">⌘K</kbd></dd>
          </div>
        </dl>
        <button type="button" class="mt-4 w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm font-medium" data-action="click->keyboard-shortcuts#hideHelp">
          Sluiten
        </button>
      </div>
    `
    help.addEventListener("click", (e) => {
      if (e.target === help) help.remove()
    })
    document.body.appendChild(help)
  }

  hideHelp() {
    document.getElementById("keyboard-shortcuts-help")?.remove()
  }

  showNotification(message, type = "info") {
    const colors = {
      info: "bg-blue-600",
      warning: "bg-amber-600",
      error: "bg-red-600"
    }

    const notification = document.createElement("div")
    notification.className = `fixed bottom-4 right-4 ${colors[type]} text-white px-4 py-3 rounded-lg shadow-lg z-50`
    notification.textContent = message
    document.body.appendChild(notification)

    setTimeout(() => {
      notification.classList.add("opacity-0", "transition-opacity", "duration-300")
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }
}
