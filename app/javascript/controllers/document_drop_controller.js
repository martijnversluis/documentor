import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone"]
  static values = { url: String }

  connect() {
    this.dragCounter = 0
  }

  dragenter(event) {
    if (this.isInternalDrag(event)) return
    event.preventDefault()
    this.dragCounter++
    this.dropzoneTarget.classList.remove("hidden")
  }

  dragover(event) {
    if (this.isInternalDrag(event)) return
    event.preventDefault()
  }

  dragleave(event) {
    if (this.isInternalDrag(event)) return
    event.preventDefault()
    this.dragCounter--
    if (this.dragCounter === 0) {
      this.dropzoneTarget.classList.add("hidden")
    }
  }

  drop(event) {
    if (this.isInternalDrag(event)) return
    event.preventDefault()
    this.dragCounter = 0
    this.dropzoneTarget.classList.add("hidden")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.uploadFiles(files)
    }
  }

  isInternalDrag(event) {
    return event.dataTransfer.types.includes("application/x-sortable") ||
           event.dataTransfer.types.includes("application/document") ||
           event.dataTransfer.types.includes("application/note")
  }

  async uploadFiles(files) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    for (const file of files) {
      const formData = new FormData()
      formData.append("files", file)

      try {
        await fetch(this.urlValue, {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken,
            "Accept": "text/html"
          },
          body: formData
        })
      } catch (error) {
        console.error("Upload failed:", error)
      }
    }

    Turbo.visit(window.location.href)
  }
}
