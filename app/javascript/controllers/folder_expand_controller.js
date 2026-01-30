import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "arrow"]
  static values = { folderId: Number }

  connect() {
    if (this.isExpanded()) {
      this.expand()
    }
  }

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.arrowTarget.classList.toggle("rotate-90")
    this.saveState()
  }

  expand() {
    this.contentTarget.classList.remove("hidden")
    this.arrowTarget.classList.add("rotate-90")
  }

  isExpanded() {
    const expanded = this.getExpandedFolders()
    return expanded.includes(this.folderIdValue)
  }

  saveState() {
    const expanded = this.getExpandedFolders()
    const isNowExpanded = !this.contentTarget.classList.contains("hidden")

    if (isNowExpanded && !expanded.includes(this.folderIdValue)) {
      expanded.push(this.folderIdValue)
    } else if (!isNowExpanded) {
      const index = expanded.indexOf(this.folderIdValue)
      if (index > -1) expanded.splice(index, 1)
    }

    localStorage.setItem("expandedFolders", JSON.stringify(expanded))
  }

  getExpandedFolders() {
    try {
      return JSON.parse(localStorage.getItem("expandedFolders")) || []
    } catch {
      return []
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
