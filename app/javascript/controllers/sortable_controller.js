import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("mousedown", this.mousedown.bind(this))
    this.element.addEventListener("dragstart", this.dragstart.bind(this))
    this.element.addEventListener("dragover", this.dragover.bind(this))
    this.element.addEventListener("dragend", this.dragend.bind(this))
    this.element.addEventListener("drop", this.drop.bind(this))
  }

  mousedown(event) {
    // Track if mousedown was on a drag handle
    this.mousedownOnHandle = !!event.target.closest("[data-drag-handle]")
  }

  dragstart(event) {
    // Only allow dragging if mousedown was on a drag handle
    if (!this.mousedownOnHandle) {
      event.preventDefault()
      return
    }

    const item = event.target.closest("[data-sortable-id]")
    if (!item) return

    event.stopPropagation()
    this.draggedItem = item
    this.isDragging = true
    item.classList.add("opacity-50")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("application/x-sortable", item.dataset.sortableId)
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    if (!this.draggedItem) return

    const item = event.target.closest("[data-sortable-id]")
    if (!item || item === this.draggedItem) return

    // Only reorder items at the same level (same parent)
    if (item.parentNode !== this.draggedItem.parentNode) return

    const rect = item.getBoundingClientRect()
    const midY = rect.top + rect.height / 2

    if (event.clientY < midY) {
      item.parentNode.insertBefore(this.draggedItem, item)
    } else {
      item.parentNode.insertBefore(this.draggedItem, item.nextSibling)
    }
  }

  dragend(event) {
    if (this.draggedItem) {
      this.draggedItem.classList.remove("opacity-50")
      this.saveOrder()
      this.draggedItem = null
    }
    this.mousedownOnHandle = false
  }

  drop(event) {
    event.preventDefault()
  }

  async saveOrder() {
    // Only select direct children, not nested sub-items
    const items = this.element.querySelectorAll(":scope > [data-sortable-id]")
    const ids = Array.from(items).map(item => item.dataset.sortableId)

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ ids })
      })
    } catch (error) {
      console.error("Failed to save order:", error)
    }
  }
}
