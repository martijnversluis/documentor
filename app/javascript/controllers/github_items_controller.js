import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "item"]
  static values = { promoteUrl: String, snoozeUrl: String, ignoreUrl: String }

  async snooze(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    try {
      const response = await fetch(this.snoozeUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ item_id: item.dataset.itemId })
      })

      if (response.ok) {
        item.remove()
        this.checkEmpty()
      }
    } catch (error) {
      console.error("Failed to snooze item:", error)
    }
  }

  async ignore(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = event.target.closest("[data-item-id]")
    if (!item) return

    try {
      const response = await fetch(this.ignoreUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ item_id: item.dataset.itemId })
      })

      if (response.ok) {
        item.remove()
        this.checkEmpty()
      }
    } catch (error) {
      console.error("Failed to ignore item:", error)
    }
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
        body: JSON.stringify({ description, url, item_id: itemId })
      })

      if (response.ok) {
        item.classList.add("bg-green-50")
        item.querySelector(".flex-1 p:first-child").insertAdjacentHTML("afterbegin",
          '<svg class="w-4 h-4 text-green-500 inline mr-1" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>'
        )
        setTimeout(() => {
          item.remove()
          this.checkEmpty()
        }, 1500)
      }
    } catch (error) {
      console.error("Failed to promote item:", error)
    }
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
}
