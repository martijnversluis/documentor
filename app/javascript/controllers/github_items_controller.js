import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "item"]
  static values = { promoteUrl: String }

  connect() {
    // Use setTimeout to ensure DOM is fully ready
    setTimeout(() => this.filterItems(), 0)
  }

  snooze(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    const itemId = item.dataset.itemId
    this.addToSnoozed(itemId)
    item.remove()
    this.checkEmpty()
  }

  ignore(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    const itemId = item.dataset.itemId
    this.addToIgnored(itemId)
    item.remove()
    this.checkEmpty()
  }

  async promote(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    const itemId = item.dataset.itemId
    const title = item.dataset.itemTitle
    const url = item.dataset.itemUrl
    const repo = item.dataset.itemRepo

    // Build description like: [owner/repo] Title
    const description = `[${repo}] ${title}`

    try {
      const response = await fetch(this.promoteUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ description, url })
      })

      if (response.ok) {
        this.addToPromoted(itemId)
        item.remove()
        this.checkEmpty()
      }
    } catch (error) {
      console.error("Failed to promote item:", error)
    }
  }

  filterItems() {
    const snoozed = this.getSnoozedItems()
    const ignored = this.getIgnoredItems()
    const promoted = this.getPromotedItems()

    // Get all items within this controller's element
    const items = this.element.querySelectorAll("[data-item-id]")

    items.forEach(item => {
      const itemId = item.dataset.itemId
      if (snoozed.includes(itemId) || ignored.includes(itemId) || promoted.includes(itemId)) {
        item.remove()
      }
    })

    this.checkEmpty()
  }

  checkEmpty() {
    const list = this.element.querySelector("ul")
    if (list && list.querySelectorAll("[data-item-id]").length === 0) {
      list.innerHTML = '<li class="text-center py-4 text-gray-500 text-sm">Geen openstaande items</li>'

      // Hide the "en X meer..." text since all visible items are gone
      const moreText = this.element.querySelector("[data-github-items-target='overflow']")
      if (moreText) moreText.remove()
    }
  }

  // Snoozed items - stored with today's date, cleared on new day
  addToSnoozed(itemId) {
    const today = this.todayString()
    const data = this.getSnoozedData()

    // Clean old entries
    if (data.date !== today) {
      data.date = today
      data.items = []
    }

    if (!data.items.includes(itemId)) {
      data.items.push(itemId)
    }

    localStorage.setItem("github_snoozed", JSON.stringify(data))
  }

  getSnoozedItems() {
    const data = this.getSnoozedData()
    const today = this.todayString()

    // Return empty if snoozed on a different day (snooze expired)
    if (data.date !== today) {
      return []
    }

    return data.items || []
  }

  getSnoozedData() {
    try {
      return JSON.parse(localStorage.getItem("github_snoozed")) || { date: null, items: [] }
    } catch {
      return { date: null, items: [] }
    }
  }

  // Ignored items - permanent until manually cleared
  addToIgnored(itemId) {
    const ignored = this.getIgnoredItems()
    if (!ignored.includes(itemId)) {
      ignored.push(itemId)
      // Keep only last 200 to prevent localStorage bloat
      const toStore = ignored.slice(-200)
      localStorage.setItem("github_ignored", JSON.stringify(toStore))
    }
  }

  getIgnoredItems() {
    try {
      return JSON.parse(localStorage.getItem("github_ignored")) || []
    } catch {
      return []
    }
  }

  todayString() {
    const today = new Date()
    return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`
  }

  // Promoted items - permanent until manually cleared
  addToPromoted(itemId) {
    const promoted = this.getPromotedItems()
    if (!promoted.includes(itemId)) {
      promoted.push(itemId)
      // Keep only last 200 to prevent localStorage bloat
      const toStore = promoted.slice(-200)
      localStorage.setItem("github_promoted", JSON.stringify(toStore))
    }
  }

  getPromotedItems() {
    try {
      return JSON.parse(localStorage.getItem("github_promoted")) || []
    } catch {
      return []
    }
  }
}
