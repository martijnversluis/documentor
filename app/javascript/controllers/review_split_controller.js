import SplitViewController from "./split_view_controller"

export default class extends SplitViewController {
  static values = {
    ...SplitViewController.values,
    storageKey: { type: String, default: "reviewSplitOpen" },
    contentMaxWidth: { type: String, default: "max-w-3xl" }
  }

  connect() {
    super.connect()

    const stepFrame = document.getElementById("current-step")
    if (stepFrame) {
      this.observer = new MutationObserver(() => this.onStepChange())
      this.observer.observe(stepFrame, { childList: true })
    }

    if (sessionStorage.getItem(this.storageKeyValue) === "true") {
      this.loadFirstLink()
    }
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
    super.disconnect()
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
}
