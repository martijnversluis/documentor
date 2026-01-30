import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "filename", "name", "date", "tags"]

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50")
  }

  dragenter(event) {
    event.preventDefault()
  }

  dragleave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.updateFilename(files[0].name)
    }
  }

  change() {
    const files = this.inputTarget.files
    if (files.length > 0) {
      this.updateFilename(files[0].name)
    }
  }

  updateFilename(name) {
    this.filenameTarget.textContent = name
    this.filenameTarget.classList.add("font-medium", "text-gray-900")

    const nameWithoutExt = name.replace(/\.[^/.]+$/, "") // Remove extension

    // Pre-fill name field with filename (underscores to spaces)
    if (this.hasNameTarget) {
      const cleanName = nameWithoutExt.replace(/_/g, " ")
      this.nameTarget.value = cleanName
      this.nameTarget.focus()
      this.nameTarget.select()
    }

    // Try to detect date from filename
    if (this.hasDateTarget) {
      const detectedDate = this.detectDate(nameWithoutExt)
      if (detectedDate) {
        this.dateTarget.value = detectedDate
      }
    }

    // Try to detect tags from filename
    if (this.hasTagsTarget) {
      const detectedTags = this.detectTags(nameWithoutExt)
      if (detectedTags.length > 0) {
        this.tagsTarget.value = detectedTags.join(", ")
      }
    }
  }

  detectTags(text) {
    if (!this.hasTagsTarget) return []

    const availableTags = JSON.parse(this.tagsTarget.dataset.availableTags || "[]")
    const normalized = text.toLowerCase().replace(/[-_]/g, " ")

    return availableTags.filter(tag => {
      const tagLower = tag.toLowerCase()
      // Match whole word (with word boundaries)
      const regex = new RegExp(`\\b${tagLower.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`)
      return regex.test(normalized)
    })
  }

  detectDate(text) {
    const today = new Date()

    // Dutch month names
    const months = {
      'januari': 0, 'jan': 0,
      'februari': 1, 'feb': 1,
      'maart': 2, 'mrt': 2,
      'april': 3, 'apr': 3,
      'mei': 4,
      'juni': 5, 'jun': 5,
      'juli': 6, 'jul': 6,
      'augustus': 7, 'aug': 7,
      'september': 8, 'sep': 8, 'sept': 8,
      'oktober': 9, 'okt': 9,
      'november': 10, 'nov': 10,
      'december': 11, 'dec': 11
    }

    // Normalize: lowercase, replace separators with spaces
    const normalized = text.toLowerCase().replace(/[-_]/g, ' ')

    // Pattern: YYYY-MM-DD or YYYY MM DD
    let match = normalized.match(/\b(20\d{2})\s*(\d{2})\s*(\d{2})\b/)
    if (match) {
      const [, year, month, day] = match
      if (parseInt(month) <= 12 && parseInt(day) <= 31) {
        return `${year}-${month}-${day}T00:00`
      }
    }

    // Pattern: DD-MM-YYYY or DD MM YYYY
    match = normalized.match(/\b(\d{2})\s*(\d{2})\s*(20\d{2})\b/)
    if (match) {
      const [, day, month, year] = match
      if (parseInt(month) <= 12 && parseInt(day) <= 31) {
        return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}T00:00`
      }
    }

    // Pattern: month name + year (e.g., "januari 2024" or "2024 januari")
    for (const [monthName, monthIndex] of Object.entries(months)) {
      const regex = new RegExp(`\\b(${monthName})\\s*(20\\d{2})\\b|\\b(20\\d{2})\\s*(${monthName})\\b`)
      match = normalized.match(regex)
      if (match) {
        const year = match[2] || match[3]
        const month = String(monthIndex + 1).padStart(2, '0')
        return `${year}-${month}-01T00:00`
      }
    }

    // Pattern: YYYY-MM (year and month only)
    match = normalized.match(/\b(20\d{2})\s*(\d{2})\b/)
    if (match) {
      const [, year, month] = match
      if (parseInt(month) <= 12) {
        return `${year}-${month}-01T00:00`
      }
    }

    // Pattern: just year (20xx)
    match = normalized.match(/\b(20\d{2})\b/)
    if (match) {
      return `${match[1]}-01-01T00:00`
    }

    // Default: today at 00:00
    const year = today.getFullYear()
    const month = String(today.getMonth() + 1).padStart(2, '0')
    const day = String(today.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}T00:00`
  }
}
