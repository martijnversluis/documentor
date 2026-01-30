import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "option", "hidden"]
  static values = {
    selected: String,
    placeholder: { type: String, default: "Zoeken..." }
  }

  connect() {
    this.isOpen = false
    this.highlightedIndex = -1
    this.setupInitialValue()
  }

  setupInitialValue() {
    if (this.selectedValue) {
      const option = this.optionTargets.find(o => o.dataset.value === this.selectedValue)
      if (option) {
        this.inputTarget.value = option.dataset.label
      }
    }
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    this.open()

    const visibleOptions = []
    this.optionTargets.forEach((option) => {
      const searchText = option.dataset.searchText.toLowerCase()
      const matches = searchText.includes(query) || query === ""
      option.classList.toggle("hidden", !matches)
      if (matches) visibleOptions.push(option)
    })

    // Auto-select first matching item
    this.highlightedIndex = visibleOptions.length > 0 ? 0 : -1
    this.updateHighlight(visibleOptions)
  }

  open() {
    if (this.isOpen) return
    this.isOpen = true
    this.dropdownTarget.classList.remove("hidden")
    this.highlightedIndex = -1
  }

  close() {
    if (!this.isOpen) return
    this.isOpen = false
    this.dropdownTarget.classList.add("hidden")
    this.highlightedIndex = -1
    this.optionTargets.forEach(o => o.classList.remove("bg-blue-50"))
  }

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }

  select(event) {
    const option = event.currentTarget
    this.selectOption(option)
  }

  selectOption(option) {
    const value = option.dataset.value
    const label = option.dataset.label

    this.hiddenTarget.value = value
    this.inputTarget.value = label
    this.selectedValue = value
    this.close()

    // Trigger change event for auto-submit
    this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  handleKeydown(event) {
    const visibleOptions = this.optionTargets.filter(o => !o.classList.contains("hidden"))

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        if (!this.isOpen) {
          this.open()
        } else {
          this.highlightedIndex = Math.min(this.highlightedIndex + 1, visibleOptions.length - 1)
          this.updateHighlight(visibleOptions)
        }
        break
      case "ArrowUp":
        event.preventDefault()
        this.highlightedIndex = Math.max(this.highlightedIndex - 1, 0)
        this.updateHighlight(visibleOptions)
        break
      case "Enter":
        event.preventDefault()
        if (this.highlightedIndex >= 0 && visibleOptions[this.highlightedIndex]) {
          this.selectOption(visibleOptions[this.highlightedIndex])
        }
        break
      case "Escape":
        this.close()
        break
      case "Tab":
        this.close()
        break
    }
  }

  updateHighlight(visibleOptions) {
    this.optionTargets.forEach(o => o.classList.remove("bg-blue-50"))
    if (this.highlightedIndex >= 0 && visibleOptions[this.highlightedIndex]) {
      visibleOptions[this.highlightedIndex].classList.add("bg-blue-50")
      visibleOptions[this.highlightedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  focusInput() {
    this.open()
    // Clear input if no real selection, so user can type immediately
    if (!this.hiddenTarget.value) {
      this.inputTarget.value = ""
    } else {
      this.inputTarget.select()
    }
  }

  clearIfEmpty() {
    // If no selection and input is empty/cleared, restore placeholder
    if (!this.hiddenTarget.value && this.inputTarget.value === "") {
      this.inputTarget.placeholder = this.placeholderValue
    }
    // If there's a selection but input doesn't match, restore the selected label
    if (this.hiddenTarget.value) {
      const option = this.optionTargets.find(o => o.dataset.value === this.hiddenTarget.value)
      if (option) {
        this.inputTarget.value = option.dataset.label
      }
    }
  }
}
