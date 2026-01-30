import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { url: String }

  async connect() {
    try {
      // Load mammoth dynamically as it's a browser global
      await this.loadMammoth()
      const response = await fetch(this.urlValue)
      const arrayBuffer = await response.arrayBuffer()
      const result = await window.mammoth.convertToHtml({ arrayBuffer })
      this.outputTarget.innerHTML = result.value
    } catch (error) {
      this.outputTarget.innerHTML = `<p class="text-red-500">Kon document niet laden: ${error.message}</p>`
    }
  }

  loadMammoth() {
    if (window.mammoth) return Promise.resolve()

    return new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = "https://cdn.jsdelivr.net/npm/mammoth@1.6.0/mammoth.browser.min.js"
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
}
