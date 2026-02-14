import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "item"]
  static values = { promoteUrl: String, dismissUrl: String }

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

  async ignore(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    const itemId = item.dataset.itemId
    // Extract the actual Gmail message ID (remove "mail-" prefix)
    const messageId = itemId.replace("mail-", "")

    // Remove from UI immediately
    item.remove()
    this.checkEmpty()

    // Call backend to mark as read and trash
    try {
      await fetch(this.dismissUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ message_id: messageId })
      })
    } catch (error) {
      console.error("Failed to dismiss mail:", error)
    }
  }

  async promote(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    const itemId = item.dataset.itemId
    const subject = item.dataset.itemSubject
    const from = item.dataset.itemFrom
    const threadId = item.dataset.itemThreadId

    // Build description like: [Mail] Van: Subject
    const description = `[Mail van ${from}] ${subject}`
    const notes = `https://mail.google.com/mail/u/0/#inbox/${threadId}`

    try {
      const response = await fetch(this.promoteUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ description, notes })
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
