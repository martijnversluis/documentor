import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "item"]
  static values = {
    url: String,
    type: String
  }

  connect() {
    this.element.addEventListener("dragover", this.dragover.bind(this))
    this.element.addEventListener("dragenter", this.dragenter.bind(this))
    this.element.addEventListener("dragleave", this.dragleave.bind(this))
    this.element.addEventListener("drop", this.drop.bind(this))
  }

  dragstart(event) {
    const item = event.target.closest("[data-document-id], [data-note-id]")
    if (item) {
      const documentId = item.dataset.documentId
      const noteId = item.dataset.noteId

      if (documentId) {
        event.dataTransfer.setData("application/document", documentId)
        event.dataTransfer.effectAllowed = "move"
      } else if (noteId) {
        event.dataTransfer.setData("application/note", noteId)
        event.dataTransfer.effectAllowed = "move"
      }
    }
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const dropzone = event.target.closest("[data-dropzone]")
    if (dropzone) {
      dropzone.classList.add("bg-blue-50", "border-blue-300")
    }
  }

  dragenter(event) {
    event.preventDefault()
  }

  dragleave(event) {
    const dropzone = event.target.closest("[data-dropzone]")
    if (dropzone && !dropzone.contains(event.relatedTarget)) {
      dropzone.classList.remove("bg-blue-50", "border-blue-300")
    }
  }

  async drop(event) {
    event.preventDefault()

    const dropzone = event.target.closest("[data-dropzone]")
    if (dropzone) {
      dropzone.classList.remove("bg-blue-50", "border-blue-300")
    }

    // Check for file uploads from system
    const files = event.dataTransfer.files
    if (files && files.length > 0) {
      const folderId = dropzone?.dataset.folderId
      const dossierId = dropzone?.dataset.dossierId
      if (folderId || dossierId) {
        await this.uploadFiles(files, folderId, dossierId)
        return
      }
    }

    const documentId = event.dataTransfer.getData("application/document")
    const noteId = event.dataTransfer.getData("application/note")

    const folderId = dropzone?.dataset.folderId
    const dossierId = dropzone?.dataset.dossierId

    if (documentId && (folderId || dossierId)) {
      await this.moveItem("documents", documentId, folderId, dossierId)
    } else if (noteId && (folderId || dossierId)) {
      await this.moveItem("notes", noteId, folderId, dossierId)
    }
  }

  async uploadFiles(files, folderId, dossierId) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    for (const file of files) {
      const formData = new FormData()
      formData.append("document[file]", file)

      // Use filename without extension as name, replace underscores with spaces
      const nameWithoutExt = file.name.replace(/\.[^/.]+$/, "").replace(/_/g, " ")
      formData.append("document[name]", nameWithoutExt)

      // Use file modification time as occurred_at date (time set to 00:00)
      const mtime = new Date(file.lastModified)
      const year = mtime.getFullYear()
      const month = String(mtime.getMonth() + 1).padStart(2, '0')
      const day = String(mtime.getDate()).padStart(2, '0')
      formData.append("document[occurred_at]", `${year}-${month}-${day}T00:00`)

      let url
      if (folderId) {
        url = `/folders/${folderId}/documents`
      } else {
        url = `/dossiers/${dossierId}/documents`
      }

      try {
        await fetch(url, {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken,
          },
          body: formData
        })
      } catch (error) {
        console.error("Failed to upload file:", error)
      }
    }

    window.location.reload()
  }

  async moveItem(type, id, folderId, dossierId) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const params = new URLSearchParams()

    if (folderId) {
      params.append("folder_id", folderId)
    } else if (dossierId) {
      params.append("dossier_id", dossierId)
    }

    try {
      const response = await fetch(`/${type}/${id}/move?${params.toString()}`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        // Reload the page to reflect changes
        window.location.reload()
      }
    } catch (error) {
      console.error("Failed to move item:", error)
    }
  }
}
