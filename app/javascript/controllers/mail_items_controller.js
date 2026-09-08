import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "item"]
  static values = { dismissUrl: String, markAsReadUrl: String }

  connect() {
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

  async delete(event) {
    await this.sendThreadAction(event, this.dismissUrlValue, "Failed to delete mail thread:")
  }

  async markAsRead(event) {
    await this.sendThreadAction(event, this.markAsReadUrlValue, "Failed to mark mail thread as read:")
  }

  async sendThreadAction(event, url, errorLabel) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    const threadId = item.dataset.itemThreadId
    item.remove()
    this.checkEmpty()

    try {
      await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ thread_id: threadId })
      })
    } catch (error) {
      console.error(errorLabel, error)
    }
  }

  filterItems() {
    const snoozed = this.getSnoozedItems()
    const ignored = this.getIgnoredItems()
    const promoted = this.getPromotedItems()

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
      list.innerHTML = '<li class="text-center py-4 text-gray-500 text-sm">Geen ongelezen berichten</li>'
    }
  }

  // Snoozed items - stored with today's date, cleared on new day
  addToSnoozed(itemId) {
    const today = this.todayString()
    const data = this.getSnoozedData()

    if (data.date !== today) {
      data.date = today
      data.items = []
    }

    if (!data.items.includes(itemId)) {
      data.items.push(itemId)
    }

    localStorage.setItem("mail_snoozed", JSON.stringify(data))
  }

  getSnoozedItems() {
    const data = this.getSnoozedData()
    const today = this.todayString()

    if (data.date !== today) {
      return []
    }

    return data.items || []
  }

  getSnoozedData() {
    try {
      return JSON.parse(localStorage.getItem("mail_snoozed")) || { date: null, items: [] }
    } catch {
      return { date: null, items: [] }
    }
  }

  // Ignored items - permanent until manually cleared
  addToIgnored(itemId) {
    const ignored = this.getIgnoredItems()
    if (!ignored.includes(itemId)) {
      ignored.push(itemId)
      const toStore = ignored.slice(-200)
      localStorage.setItem("mail_ignored", JSON.stringify(toStore))
    }
  }

  getIgnoredItems() {
    try {
      return JSON.parse(localStorage.getItem("mail_ignored")) || []
    } catch {
      return []
    }
  }

  // Promoted items - permanent until manually cleared
  addToPromoted(itemId) {
    const promoted = this.getPromotedItems()
    if (!promoted.includes(itemId)) {
      promoted.push(itemId)
      const toStore = promoted.slice(-200)
      localStorage.setItem("mail_promoted", JSON.stringify(toStore))
    }
  }

  getPromotedItems() {
    try {
      return JSON.parse(localStorage.getItem("mail_promoted")) || []
    } catch {
      return []
    }
  }

  todayString() {
    const today = new Date()
    return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`
  }
}
