import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["foldersContainer", "actionsContainer", "folderRow", "actionRow"]
  static values = { contexts: Array }

  get contextSelectHtml() {
    const options = this.contextsValue.map(ctx => `
      <div data-searchable-select-target="option"
           data-value="${ctx}"
           data-label="@${ctx}"
           data-search-text="${ctx.toLowerCase()}"
           data-action="click->searchable-select#select"
           class="px-3 py-2 text-sm hover:bg-gray-50 cursor-pointer">
        <span class="text-teal-600">@</span>${ctx}
      </div>
    `).join('')

    return `
      <div data-controller="searchable-select"
           data-searchable-select-selected-value=""
           data-searchable-select-placeholder-value="Geen context"
           data-action="click@window->searchable-select#handleClickOutside"
           class="relative w-full">
        <input type="hidden" name="dossier_template[action_items_data][][context]" value="" data-searchable-select-target="hidden">
        <div class="relative">
          <input type="text"
                 data-searchable-select-target="input"
                 data-action="input->searchable-select#filter keydown->searchable-select#handleKeydown focus->searchable-select#focusInput blur->searchable-select#clearIfEmpty"
                 value=""
                 placeholder="Geen context"
                 autocomplete="off"
                 class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-8">
          <button type="button"
                  data-action="click->searchable-select#toggle"
                  class="absolute inset-y-0 right-0 flex items-center px-2 text-gray-400 hover:text-gray-600">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
            </svg>
          </button>
        </div>
        <div data-searchable-select-target="dropdown"
             class="hidden absolute z-50 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-y-auto">
          <div data-searchable-select-target="option"
               data-value=""
               data-label="Geen context"
               data-search-text="geen context"
               data-action="click->searchable-select#select"
               class="px-3 py-2 text-sm text-gray-500 hover:bg-gray-50 cursor-pointer">
            Geen context
          </div>
          ${options}
        </div>
      </div>
    `
  }

  addFolder() {
    const html = `
      <div class="flex items-center gap-2" data-template-form-target="folderRow">
        <input type="text" name="dossier_template[folders_data][][name]" class="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="Mapnaam">
        <button type="button" data-action="click->template-form#removeFolder" class="p-2 text-gray-400 hover:text-red-600">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    `
    this.foldersContainerTarget.insertAdjacentHTML("beforeend", html)
  }

  removeFolder(event) {
    event.target.closest("[data-template-form-target='folderRow']").remove()
  }

  addAction() {
    const html = `
      <div class="flex items-start gap-2 p-3 bg-gray-50 rounded-lg" data-template-form-target="actionRow">
        <div class="flex-1 space-y-2">
          <input type="text" name="dossier_template[action_items_data][][description]" class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="Beschrijving">
          <div class="grid grid-cols-3 gap-2">
            ${this.contextSelectHtml}
            <select name="dossier_template[action_items_data][][estimated_minutes]" class="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">Onbekend</option>
              <option value="5">5 min</option>
              <option value="15">15 min</option>
              <option value="30">30 min</option>
              <option value="60">1 uur</option>
              <option value="120">2+ uur</option>
            </select>
            <select name="dossier_template[action_items_data][][recurrence]" class="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">Eenmalig</option>
              <option value="weekly">Wekelijks</option>
              <option value="monthly">Maandelijks</option>
              <option value="quarterly">Per kwartaal</option>
              <option value="yearly">Jaarlijks</option>
            </select>
          </div>
        </div>
        <button type="button" data-action="click->template-form#removeAction" class="p-2 text-gray-400 hover:text-red-600">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    `
    this.actionsContainerTarget.insertAdjacentHTML("beforeend", html)
  }

  removeAction(event) {
    event.target.closest("[data-template-form-target='actionRow']").remove()
  }
}
