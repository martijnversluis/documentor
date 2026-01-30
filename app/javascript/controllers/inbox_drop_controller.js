import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone"]
  static values = {
    documentsUrl: String,
    notesUrl: String,
    actionItemsUrl: String
  }

  connect() {
    this.dragCounter = 0
  }

  dragenter(event) {
    // Ignore sortable drags
    if (event.dataTransfer.types.includes("application/x-sortable")) return

    event.preventDefault()
    this.dragCounter++
    this.showDropzone()
  }

  dragover(event) {
    // Ignore sortable drags
    if (event.dataTransfer.types.includes("application/x-sortable")) return

    event.preventDefault()
  }

  dragleave(event) {
    // Ignore sortable drags
    if (event.dataTransfer.types.includes("application/x-sortable")) return

    event.preventDefault()
    this.dragCounter--
    if (this.dragCounter === 0) {
      this.hideDropzone()
    }
  }

  drop(event) {
    // Ignore sortable drags
    if (event.dataTransfer.types.includes("application/x-sortable")) return

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
      this.createLinkNote(uri || text.trim(), html)
    } else if (text && text.trim()) {
      this.createNote(text.trim())
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

  showDropzone() {
    this.dropzoneTarget.classList.remove("hidden")
  }

  hideDropzone() {
    this.dropzoneTarget.classList.add("hidden")
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
          Turbo.visit(window.location.href)
        }
      } catch (error) {
        console.error("Upload failed:", error)
      }
    }
  }

  async createNote(text) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    // Use first line as title, rest as content
    const lines = text.split("\n")
    const title = lines[0].substring(0, 100) || "Gedropt notitie"
    const content = lines.length > 1 ? lines.slice(1).join("\n") : text

    const formData = new FormData()
    formData.append("note[title]", title)
    formData.append("note[content]", content)

    try {
      const response = await fetch(this.notesUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        Turbo.visit(window.location.href)
      }
    } catch (error) {
      console.error("Create note failed:", error)
    }
  }

  async createLinkNote(url, html) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    // Try to extract title from HTML
    let linkTitle = this.extractTitleFromHtml(html)

    // Format: "Link text\n[url](url)" or just "[url](url)" if no title
    let description
    if (linkTitle && linkTitle !== url) {
      description = `${linkTitle}\n[${url}](${url})`
    } else {
      description = `[${url}](${url})`
    }

    const formData = new FormData()
    formData.append("action_item[description]", description)

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
        Turbo.visit(window.location.href)
      }
    } catch (error) {
      console.error("Create link action item failed:", error)
    }
  }
}
