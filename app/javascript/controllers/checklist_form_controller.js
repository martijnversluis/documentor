import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "sectionTemplate"]

  connect() {
    this.itemIndex = this.container.querySelectorAll('.checklist-item').length
  }

  get container() {
    return this.containerTarget
  }

  addSection(event) {
    event.preventDefault()
    const sectionName = prompt("Naam van de nieuwe sectie:")
    if (!sectionName || !sectionName.trim()) return

    const sectionHtml = this.createSectionHtml(sectionName.trim())
    this.container.insertAdjacentHTML('beforeend', sectionHtml)
  }

  addItemToSection(event) {
    event.preventDefault()
    const section = event.target.closest('[data-section]')
    const sectionName = section.dataset.section
    const itemsContainer = section.querySelector('[data-section-items]')

    const template = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.itemIndex++)
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = template

    // Set the section value
    const sectionInput = tempDiv.querySelector('input[name*="[section]"]')
    if (sectionInput) {
      sectionInput.value = sectionName
    }

    itemsContainer.insertAdjacentHTML('beforeend', tempDiv.innerHTML)
  }

  addUngroupedItem(event) {
    event.preventDefault()
    const ungroupedContainer = this.container.querySelector('[data-ungrouped-items]')

    const template = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.itemIndex++)
    ungroupedContainer.insertAdjacentHTML('beforeend', template)
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest('.checklist-item')
    const destroyInput = item.querySelector('input[name*="[_destroy]"]')

    if (destroyInput && destroyInput.name.includes('NEW_RECORD') === false && !destroyInput.name.includes(this.itemIndex.toString())) {
      // Existing record - mark for destruction
      destroyInput.value = '1'
      item.style.display = 'none'
    } else {
      // New record - just remove from DOM
      item.remove()
    }
  }

  removeSection(event) {
    event.preventDefault()
    if (!confirm('Weet je zeker dat je deze sectie wilt verwijderen? Alle items worden ook verwijderd.')) return

    const section = event.target.closest('[data-section]')
    const items = section.querySelectorAll('.checklist-item')

    items.forEach(item => {
      const destroyInput = item.querySelector('input[name*="[_destroy]"]')
      if (destroyInput) {
        destroyInput.value = '1'
      }
    })

    section.remove()
  }

  createSectionHtml(sectionName) {
    return `
      <div data-section="${this.escapeHtml(sectionName)}" class="border border-gray-200 rounded-lg overflow-hidden">
        <div class="bg-gray-100 px-4 py-2 flex items-center justify-between">
          <h4 class="font-medium text-gray-700">${this.escapeHtml(sectionName)}</h4>
          <button type="button" data-action="checklist-form#removeSection" class="text-gray-400 hover:text-red-600">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        <div data-section-items class="p-3 space-y-2 bg-white"></div>
        <div class="px-3 pb-3 bg-white">
          <button type="button" data-action="checklist-form#addItemToSection" class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            Item toevoegen
          </button>
        </div>
      </div>
    `
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
