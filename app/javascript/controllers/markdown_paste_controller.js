import { Controller } from "@hotwired/stimulus"
import TurndownService from "turndown"

export default class extends Controller {
  connect() {
    console.log("markdown-paste controller connected")
    this.turndownService = new TurndownService({
      headingStyle: "atx",
      codeBlockStyle: "fenced"
    })

    // Keep line breaks
    this.turndownService.addRule("lineBreak", {
      filter: "br",
      replacement: () => "\n"
    })

    this.element.addEventListener("paste", this.handlePaste.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("paste", this.handlePaste.bind(this))
  }

  handlePaste(event) {
    const clipboardData = event.clipboardData
    if (!clipboardData) return

    const html = clipboardData.getData("text/html")
    if (!html) return

    // Prevent default paste
    event.preventDefault()

    // Convert HTML to markdown
    const markdown = this.turndownService.turndown(html)

    // Insert at cursor position
    const textarea = this.element
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const text = textarea.value

    textarea.value = text.substring(0, start) + markdown + text.substring(end)

    // Move cursor to end of inserted text
    const newPosition = start + markdown.length
    textarea.setSelectionRange(newPosition, newPosition)

    // Trigger input event for auto-save controllers
    textarea.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
