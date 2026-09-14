import SplitViewController from "controllers/split_view_controller"

export default class extends SplitViewController {
  static values = {
    ...SplitViewController.values,
    storageKey: { type: String, default: "powerThroughSplitOpen" },
    contentMaxWidth: { type: String, default: "max-w-3xl" }
  }

  connect() {
    super.connect()

    if (!this.panelTarget.classList.contains("hidden")) {
      this.loadFirstLink()
    }
  }

  loadFirstLink() {
    const link = this.contentTarget.querySelector("a[target='_blank']")
    if (!link) return

    this.loadInIframe(link.href, link.textContent.trim() || link.href)
  }
}
