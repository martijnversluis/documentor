import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("dragenter", this.dragenter.bind(this))
    this.element.addEventListener("dragover", this.dragover.bind(this))
    this.element.addEventListener("drop", this.drop.bind(this))
  }

  dragenter(event) {
    // Ignore sortable drags
    if (event.dataTransfer.types.includes("application/x-sortable")) return
  }

  dragover(event) {
    // Ignore sortable drags
    if (event.dataTransfer.types.includes("application/x-sortable")) return

    event.preventDefault()
  }

  drop(event) {
    // Ignore sortable drags
    if (event.dataTransfer.types.includes("application/x-sortable")) return

    event.preventDefault()

    const text = event.dataTransfer.getData("text/plain")
    const html = event.dataTransfer.getData("text/html")
    const uri = event.dataTransfer.getData("text/uri-list")

    if (uri || this.isUrl(text)) {
      this.createLinkItem(uri || text.trim(), html)
    } else if (text && text.trim()) {
      this.createTextItem(text.trim())
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

  async createLinkItem(url, html) {
    let linkTitle = this.extractTitleFromHtml(html)

    let description
    if (linkTitle && linkTitle !== url) {
      description = `${linkTitle}\n[${url}](${url})`
    } else {
      description = `[${url}](${url})`
    }

    await this.createItem(description)
  }

  async createTextItem(text) {
    await this.createItem(text)
  }

  async createItem(description) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    const formData = new FormData()
    formData.append("action_item[description]", description)

    try {
      const response = await fetch(this.urlValue, {
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
      console.error("Create action item failed:", error)
    }
  }
}
