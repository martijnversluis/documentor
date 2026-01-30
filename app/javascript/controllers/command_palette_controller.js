import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "input", "results", "actionForm", "actionInput"]
  static values = {
    items: Array,
    searchUrl: { type: String, default: "/search/quick" }
  }

  connect() {
    document.addEventListener("keydown", this.handleKeydown.bind(this))
    this.selectedIndex = 0
    this.showingActionForm = false
    this.searchResults = []
    this.searchTimeout = null
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    // Command+K or Ctrl+K to open
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.open()
    }

    // Escape to close
    if (event.key === "Escape" && this.isOpen()) {
      event.preventDefault()
      if (this.showingActionForm) {
        this.hideActionForm()
      } else {
        this.close()
      }
    }
  }

  open() {
    this.dialogTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.hideActionForm()
    this.searchResults = []
    this.filter()
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.dialogTarget.classList.add("hidden")
    this.hideActionForm()
    document.body.classList.remove("overflow-hidden")
  }

  isOpen() {
    return !this.dialogTarget.classList.contains("hidden")
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const items = this.itemsValue
    const filtered = query === ""
      ? items
      : items.filter(item =>
          item.name.toLowerCase().includes(query) ||
          item.keywords?.some(k => k.toLowerCase().includes(query))
        )

    this.selectedIndex = 0
    this.renderResults(filtered, query)

    // Debounce search
    if (this.searchTimeout) clearTimeout(this.searchTimeout)
    if (query.length >= 2) {
      this.searchTimeout = setTimeout(() => this.fetchSearchResults(query), 200)
    } else {
      this.searchResults = []
    }
  }

  async fetchSearchResults(query) {
    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`)
      if (response.ok) {
        this.searchResults = await response.json()
        this.renderResults(this.getFilteredItems(query), query)
      }
    } catch (error) {
      console.error("Search failed:", error)
    }
  }

  getFilteredItems(query) {
    const items = this.itemsValue
    return query === ""
      ? items
      : items.filter(item =>
          item.name.toLowerCase().includes(query) ||
          item.keywords?.some(k => k.toLowerCase().includes(query))
        )
  }

  renderResults(items, query = "") {
    let html = ""

    // Actions section
    if (items.length > 0) {
      html += `<div class="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wide bg-gray-50">Acties</div>`
      html += items.map((item, index) => this.renderActionItem(item, index)).join('')
    }

    // Search results section
    if (this.searchResults.length > 0) {
      const offset = items.length
      html += `<div class="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wide bg-gray-50 border-t border-gray-200">Zoekresultaten</div>`
      html += this.searchResults.map((result, index) => this.renderSearchResult(result, offset + index)).join('')
    }

    // Show all results option
    if (query.length >= 2) {
      const totalIndex = items.length + this.searchResults.length
      html += `
        <div class="border-t border-gray-200">
          <button type="button"
                  class="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-100 ${totalIndex === this.selectedIndex ? 'bg-gray-100' : ''}"
                  data-action="click->command-palette#goToSearch"
                  data-query="${this.escapeHtml(query)}">
            <span class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-lg bg-blue-100">
              <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
            </span>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900">Zoek naar "${this.escapeHtml(query)}"</p>
              <p class="text-xs text-gray-500">Bekijk alle resultaten</p>
            </div>
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
          </button>
        </div>
      `
    }

    this.resultsTarget.innerHTML = html
  }

  renderActionItem(item, index) {
    return `
      <button type="button"
              class="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-100 ${index === this.selectedIndex ? 'bg-gray-100' : ''}"
              data-action="click->command-palette#select"
              data-url="${item.url}"
              data-item-action="${item.action || ''}"
              data-turbo-frame="${item.turboFrame || '_top'}">
        <span class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-lg ${item.iconBg || 'bg-gray-100'}">
          ${item.icon}
        </span>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900">${item.name}</p>
          ${item.description ? `<p class="text-xs text-gray-500">${item.description}</p>` : ''}
        </div>
        ${item.shortcut ? `<kbd class="hidden sm:inline-flex px-2 py-1 text-xs text-gray-400 bg-gray-100 rounded">${item.shortcut}</kbd>` : ''}
      </button>
    `
  }

  renderSearchResult(result, index) {
    const icons = {
      dossier: `<svg class="w-4 h-4 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"></path></svg>`,
      document: `<svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>`,
      note: `<svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>`
    }
    const iconBgs = {
      dossier: 'bg-yellow-100',
      document: 'bg-blue-100',
      note: 'bg-green-100'
    }

    return `
      <button type="button"
              class="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-100 ${index === this.selectedIndex ? 'bg-gray-100' : ''}"
              data-action="click->command-palette#selectSearchResult"
              data-url="${result.url}">
        <span class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-lg ${iconBgs[result.icon] || 'bg-gray-100'}">
          ${icons[result.icon] || icons.document}
        </span>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 truncate">${this.escapeHtml(result.name)}</p>
          ${result.description ? `<p class="text-xs text-gray-500 truncate">${this.escapeHtml(result.description)}</p>` : ''}
        </div>
        <span class="text-xs text-gray-400 capitalize">${result.type}</span>
      </button>
    `
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  navigate(event) {
    if (this.showingActionForm) return

    const items = this.resultsTarget.querySelectorAll('button')
    if (items.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
      this.updateSelection(items)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
      this.updateSelection(items)
    } else if (event.key === "Enter") {
      event.preventDefault()
      items[this.selectedIndex]?.click()
    }
  }

  updateSelection(items) {
    items.forEach((item, index) => {
      item.classList.toggle('bg-gray-100', index === this.selectedIndex)
    })
    items[this.selectedIndex]?.scrollIntoView({ block: 'nearest' })
  }

  select(event) {
    const url = event.currentTarget.dataset.url
    const turboFrame = event.currentTarget.dataset.turboFrame
    const itemAction = event.currentTarget.dataset.itemAction

    if (itemAction === "action_item") {
      this.showActionForm()
      return
    }

    this.close()

    if (turboFrame === "modal") {
      Turbo.visit(url, { frame: "modal" })
    } else {
      Turbo.visit(url)
    }
  }

  selectSearchResult(event) {
    const url = event.currentTarget.dataset.url
    this.close()
    Turbo.visit(url)
  }

  goToSearch(event) {
    const query = event.currentTarget.dataset.query
    this.close()
    Turbo.visit(`/search?q=${encodeURIComponent(query)}`)
  }

  showActionForm() {
    this.showingActionForm = true
    this.resultsTarget.classList.add("hidden")
    this.actionFormTarget.classList.remove("hidden")
    this.inputTarget.classList.add("hidden")
    this.actionInputTarget.focus()
  }

  hideActionForm() {
    this.showingActionForm = false
    this.resultsTarget.classList.remove("hidden")
    this.actionFormTarget.classList.add("hidden")
    this.inputTarget.classList.remove("hidden")
    if (this.hasActionInputTarget) {
      this.actionInputTarget.value = ""
    }
  }

  backdropClick(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
}
