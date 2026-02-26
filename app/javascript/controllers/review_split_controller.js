import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "iframe", "content", "toggleIcon", "url", "spinner"]

  connect() {
    this.mainEl = this.element.closest("main")
    this.iframeTarget.addEventListener("load", this.hideSpinner.bind(this))

    const stepFrame = document.getElementById("current-step")
    if (stepFrame) {
      this.observer = new MutationObserver(() => this.onStepChange())
      this.observer.observe(stepFrame, { childList: true })
    }

    if (sessionStorage.getItem("reviewSplitOpen") === "true") {
      this.open()
      this.loadFirstLink()
    }
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
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
    this.contentTarget.classList.remove("max-w-3xl", "mx-auto")
    this.contentTarget.classList.add("w-2/5", "min-w-0")
    this.toggleIconTarget.classList.add("text-blue-600")
    this.toggleIconTarget.classList.remove("text-gray-500")
    if (this.mainEl) this.mainEl.classList.remove("max-w-7xl")
    sessionStorage.setItem("reviewSplitOpen", "true")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.contentTarget.classList.add("max-w-3xl", "mx-auto")
    this.contentTarget.classList.remove("w-2/5", "min-w-0")
    this.toggleIconTarget.classList.remove("text-blue-600")
    this.toggleIconTarget.classList.add("text-gray-500")
    if (this.mainEl) this.mainEl.classList.add("max-w-7xl")
    sessionStorage.setItem("reviewSplitOpen", "false")
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

  onStepChange() {
    const stepFrame = document.getElementById("current-step")
    if (stepFrame) {
      stepFrame.scrollIntoView({ behavior: "smooth", block: "start" })
    }
    this.loadFirstLink()
  }

  loadFirstLink() {
    if (this.panelTarget.classList.contains("hidden")) return

    const link = this.contentTarget.querySelector("a[target='_blank']")
    if (!link) return

    this.loadInIframe(link.href, link.textContent.trim() || link.href)
  }

  interceptLink(event) {
    if (this.panelTarget.classList.contains("hidden")) return

    const link = event.target.closest("a[target='_blank']")
    if (!link) return

    event.preventDefault()
    this.loadInIframe(link.href, link.textContent.trim() || link.href)
  }
}
