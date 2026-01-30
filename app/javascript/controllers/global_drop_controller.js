import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone"]
  static values = {
    documentsUrl: String,
    actionItemsUrl: String
  }

  connect() {
    this.dragCounter = 0
  }

  isInternalDrag(event) {
    // Ignore sortable drags (internal reordering)
    if (event.dataTransfer.types.includes("application/x-sortable")) return true
    // Ignore document/note drags (dossier page)
    if (event.dataTransfer.types.includes("application/document")) return true
    if (event.dataTransfer.types.includes("application/note")) return true
    return false
  }

  dragenter(event) {
    if (this.isInternalDrag(event)) return

    event.preventDefault()
    this.dragCounter++
    this.showDropzone()
  }

  dragover(event) {
    if (this.isInternalDrag(event)) return

    event.preventDefault()
  }

  dragleave(event) {
    if (this.isInternalDrag(event)) return

    event.preventDefault()
    this.dragCounter--
    if (this.dragCounter === 0) {
      this.hideDropzone()
    }
  }

  drop(event) {
    if (this.isInternalDrag(event)) return

    event.preventDefault()
    this.dragCounter = 0
    this.hideDropzone()

    const files = event.dataTransfer.files
    const text = event.dataTransfer.getData("text/plain")
    const html = event.dataTransfer.getData("text/html")
    const uri = event.dataTransfer.getData("text/uri-list")

    if (files.length > 0) {
      this.uploadFiles(files)
    } else if (uri || this.isUrl(text)) {
      this.createActionItemFromUrl(uri || text.trim(), html)
    } else if (text && text.trim()) {
      this.createActionItemFromText(text.trim())
    }
  }

  isUrl(text) {
    if (!text) return false
    try {
      const url = new URL(text.trim())
      return url.protocol === "http:" || url.protocol === "https:"
    } catch {
      return false
    }
  }

  extractTitleFromHtml(html) {
    if (!html) return null
    const match = html.match(/<a[^>]*>([^<]+)<\/a>/i)
    return match ? match[1].trim() : null
  }

  truncateText(text, maxLength = 100) {
    if (text.length <= maxLength) return text
    return text.substring(0, maxLength).trim() + "..."
  }

  showDropzone() {
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("hidden")
    }
  }

  hideDropzone() {
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.add("hidden")
    }
  }

  async uploadFiles(files) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    for (const file of files) {
      const formData = new FormData()
      formData.append("document[file]", file)
      formData.append("document[name]", file.name.replace(/\.[^/.]+$/, "").replace(/_/g, " "))

      try {
        const response = await fetch(this.documentsUrlValue, {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken,
            "Accept": "text/vnd.turbo-stream.html"
          },
          body: formData
        })

        if (response.ok) {
          this.showNotification(`Document "${file.name}" toegevoegd aan inbox`)
        }
      } catch (error) {
        console.error("Upload failed:", error)
      }
    }
  }

  async createActionItemFromText(text) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    // Use first line as description, truncated if needed
    const lines = text.split("\n")
    const firstLine = lines[0]
    const description = this.truncateText(firstLine, 100)

    // Store full text in notes if it's longer than the description
    const notes = text.length > description.length ? text : null

    const formData = new FormData()
    formData.append("action_item[description]", description)
    if (notes) {
      formData.append("action_item[notes]", notes)
    }

    try {
      const response = await fetch(this.actionItemsUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        this.showNotification(`Actiepunt "${description}" toegevoegd aan inbox`)
      }
    } catch (error) {
      console.error("Create action item failed:", error)
    }
  }

  async createActionItemFromUrl(url, html) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    // Try to extract title from HTML
    let linkTitle = this.extractTitleFromHtml(html)

    // Use link title as description, or the URL itself
    let description = linkTitle && linkTitle !== url ? linkTitle : url
    description = this.truncateText(description, 100)

    // Store formatted link in notes
    const notes = linkTitle && linkTitle !== url
      ? `${linkTitle}\n[${url}](${url})`
      : `[${url}](${url})`

    const formData = new FormData()
    formData.append("action_item[description]", description)
    formData.append("action_item[notes]", notes)

    try {
      const response = await fetch(this.actionItemsUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        this.showNotification(`Link "${description}" toegevoegd aan inbox`)
      }
    } catch (error) {
      console.error("Create link action item failed:", error)
    }
  }

  showNotification(message) {
    // Create a temporary notification
    const notification = document.createElement("div")
    notification.className = "fixed bottom-4 right-4 bg-green-600 text-white px-4 py-3 rounded-lg shadow-lg z-50 animate-fade-in"
    notification.textContent = message
    document.body.appendChild(notification)

    // Remove after 3 seconds
    setTimeout(() => {
      notification.classList.add("opacity-0", "transition-opacity", "duration-300")
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }
}
