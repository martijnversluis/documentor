import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "iframe", "content", "toggleIcon", "url", "spinner"]
  static values = {
    storageKey: { type: String, default: "splitViewOpen" },
    contentMaxWidth: { type: String, default: "max-w-2xl" }
  }

  connect() {
    this.mainEl = this.element.closest("main")
    this.iframeTarget.addEventListener("load", this.hideSpinner.bind(this))

    if (sessionStorage.getItem(this.storageKeyValue) === "true") {
      this.open()
    }
  }

  disconnect() {
    if (this.mainEl) {
      this.mainEl.classList.add("max-w-7xl")
    }
  }

  toggle() {
    if (this.panelTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.contentTarget.classList.remove(this.contentMaxWidthValue, "mx-auto")
    this.contentTarget.classList.add("w-2/5", "min-w-0")
    this.toggleIconTarget.classList.add("text-blue-600")
    this.toggleIconTarget.classList.remove("text-gray-500")
    if (this.mainEl) this.mainEl.classList.remove("max-w-7xl")
    sessionStorage.setItem(this.storageKeyValue, "true")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.contentTarget.classList.add(this.contentMaxWidthValue, "mx-auto")
    this.contentTarget.classList.remove("w-2/5", "min-w-0")
    this.toggleIconTarget.classList.remove("text-blue-600")
    this.toggleIconTarget.classList.add("text-gray-500")
    if (this.mainEl) this.mainEl.classList.add("max-w-7xl")
    sessionStorage.setItem(this.storageKeyValue, "false")
  }

  showSpinner() {
    this.spinnerTarget.classList.remove("hidden")
  }

  hideSpinner() {
    this.spinnerTarget.classList.add("hidden")
    try {
      const main = this.iframeTarget.contentDocument?.querySelector("main")
      if (main) main.scrollIntoView()
    } catch (_) {
      // cross-origin, can't access iframe content
    }
  }

  loadInIframe(href, label) {
    this.iframeTarget.src = href
    this.urlTarget.textContent = label
    this.showSpinner()
  }

  interceptLink(event) {
    if (this.panelTarget.classList.contains("hidden")) return

    const link = event.target.closest("a[target='_blank']")
    if (!link) return

    event.preventDefault()
    this.loadInIframe(link.href, link.textContent.trim() || link.href)
  }
}
