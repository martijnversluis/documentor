import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, filename: String }

  async download(event) {
    event.preventDefault()

    try {
      const response = await fetch(this.urlValue)
      const blob = await response.blob()

      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = this.filenameValue
      document.body.appendChild(a)
      a.click()

      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
    } catch (error) {
      console.error("Download failed:", error)
    }
  }
}
