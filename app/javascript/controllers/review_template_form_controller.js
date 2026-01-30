import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stepsContainer", "stepRow", "emptyMessage", "positionField", "destroyField"]

  connect() {
    this.stepIndex = this.stepRowTargets.length
    this.initializeDragAndDrop()
  }

  addStep() {
    const html = this.stepRowTemplate(this.stepIndex)
    this.stepsContainerTarget.insertAdjacentHTML("beforeend", html)
    this.stepIndex++

    if (this.hasEmptyMessageTarget) {
      this.emptyMessageTarget.style.display = "none"
    }

    // Focus on the new title field
    const newRow = this.stepsContainerTarget.lastElementChild
    const titleField = newRow.querySelector("input[type='text']")
    if (titleField) titleField.focus()
  }

  removeStep(event) {
    const row = event.target.closest("[data-review-template-form-target='stepRow']")
    if (!row) return

    const destroyField = row.querySelector("input[name*='_destroy']")
    if (destroyField && destroyField.value !== "1") {
      // Existing record - mark for destruction
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      // New record - just remove
      row.remove()
    }

    this.updatePositions()
  }

  updatePositions() {
    const visibleRows = this.stepRowTargets.filter(row => row.style.display !== "none")
    visibleRows.forEach((row, index) => {
      const positionField = row.querySelector("input[name*='position']")
      if (positionField) {
        positionField.value = index
      }
    })
  }

  initializeDragAndDrop() {
    this.element.addEventListener("dragstart", this.dragstart.bind(this))
    this.element.addEventListener("dragover", this.dragover.bind(this))
    this.element.addEventListener("dragend", this.dragend.bind(this))
    this.element.addEventListener("drop", this.drop.bind(this))
  }

  dragstart(event) {
    const item = event.target.closest("[data-review-template-form-target='stepRow']")
    if (!item) return

    this.draggedItem = item
    item.classList.add("opacity-50")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "")
  }

  dragover(event) {
    event.preventDefault()
    const item = event.target.closest("[data-review-template-form-target='stepRow']")
    if (!item || item === this.draggedItem) return

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
      this.draggedItem = null
      this.updatePositions()
    }
  }

  drop(event) {
    event.preventDefault()
  }

  stepRowTemplate(index) {
    return `
      <div class="flex items-start gap-3 p-4 bg-gray-50 rounded-lg" data-review-template-form-target="stepRow" draggable="true">
        <div class="flex-shrink-0 mt-2 text-gray-400 cursor-grab">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8h16M4 16h16"></path>
          </svg>
        </div>
        <div class="flex-1 space-y-3">
          <input type="hidden" name="review_template[review_template_steps_attributes][${index}][position]" value="${index}" data-review-template-form-target="positionField">
          <div>
            <input type="text" name="review_template[review_template_steps_attributes][${index}][title]"
                   class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                   placeholder="Stap titel">
          </div>
          <div>
            <textarea name="review_template[review_template_steps_attributes][${index}][description]" rows="3"
                      class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="Beschrijving (markdown ondersteund)"></textarea>
          </div>
        </div>
        <button type="button" data-action="click->review-template-form#removeStep" class="flex-shrink-0 p-2 text-gray-400 hover:text-red-600">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    `
  }
}
