// HeyDocumentor Content Script
(function() {
  'use strict';

  const DEFAULT_HOST = 'http://localhost:3000';
  let documentorHost = DEFAULT_HOST;
  let selectedAttachments = new Set();

  // Load settings
  chrome.storage.sync.get(['documentorHost'], (result) => {
    documentorHost = result.documentorHost || DEFAULT_HOST;
  });

  // Watch for storage changes
  chrome.storage.onChanged.addListener((changes) => {
    if (changes.documentorHost) {
      documentorHost = changes.documentorHost.newValue || DEFAULT_HOST;
    }
  });

  // SVG Icons
  const icons = {
    note: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
    </svg>`,
    action: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="12" cy="12" r="10"/>
      <path d="M9 12l2 2 4-4"/>
    </svg>`,
    check: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="20 6 9 17 4 12"/>
    </svg>`,
    doc: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
      <polyline points="14 2 14 8 20 8"/>
    </svg>`
  };

  // Initialize
  function init() {
    console.log('HeyDocumentor: initializing');
    injectUI();
    observeDOM();

    // Also re-inject on Turbo navigation
    document.addEventListener('turbo:load', () => {
      console.log('HeyDocumentor: turbo:load');
      setTimeout(injectUI, 100);
    });
    document.addEventListener('turbo:render', () => {
      console.log('HeyDocumentor: turbo:render');
      setTimeout(injectUI, 100);
    });
  }

  // Observe DOM changes to detect navigation
  let debounceTimer = null;
  function observeDOM() {
    const observer = new MutationObserver((mutations) => {
      // Debounce to avoid excessive calls
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(injectUI, 200);
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // Inject UI elements
  function injectUI() {
    injectBottomBarButtons();
    injectAttachmentCheckboxes();
  }

  // Find the bottom action bar - look for the bar with Reply/More buttons
  function findBottomBar() {
    // Method 1: Find by looking for "Reply Now" or "More" text
    const allElements = document.querySelectorAll('*');

    for (const el of allElements) {
      const text = el.textContent?.trim();
      if (text === 'More' || text === 'Reply Now') {
        // Walk up to find the container with multiple action buttons
        let parent = el.parentElement;
        while (parent && parent !== document.body) {
          const children = parent.children;
          let actionCount = 0;
          for (const child of children) {
            const childText = child.textContent?.trim();
            if (['Reply Now', 'Reply Later', 'Set Aside', 'Bubble Up', 'More'].some(t => childText?.includes(t))) {
              actionCount++;
            }
          }
          if (actionCount >= 3) {
            console.log('HeyDocumentor: found bottom bar', parent);
            return parent;
          }
          parent = parent.parentElement;
        }
      }
    }

    console.log('HeyDocumentor: bottom bar not found');
    return null;
  }

  // Inject buttons into bottom bar
  function injectBottomBarButtons() {
    // Don't inject if already done
    if (document.querySelector('.heydoc-btn')) {
      return;
    }

    const bottomBar = findBottomBar();
    if (!bottomBar) return;

    // Find the "More" button to insert before it
    let moreBtn = null;
    for (const child of bottomBar.children) {
      if (child.textContent?.trim().includes('More')) {
        moreBtn = child;
        break;
      }
    }

    if (!moreBtn) {
      console.log('HeyDocumentor: More button not found in bottom bar');
      return;
    }

    console.log('HeyDocumentor: injecting buttons before More');

    // Create Note button
    const noteBtn = createButton('Notitie', icons.note, () => {
      openModal('note');
    });

    // Create Action Item button
    const actionBtn = createButton('Actiepunt', icons.action, () => {
      openModal('action');
    });

    // Insert before More button
    bottomBar.insertBefore(noteBtn, moreBtn);
    bottomBar.insertBefore(actionBtn, moreBtn);
  }

  // Create a bottom bar button
  function createButton(label, icon, onClick) {
    const btn = document.createElement('div');
    btn.className = 'heydoc-btn';
    btn.innerHTML = `${icon}<span>${label}</span>`;
    btn.addEventListener('click', onClick);
    return btn;
  }

  // Inject checkboxes on attachment cards
  function injectAttachmentCheckboxes() {
    // Find attachment elements (files shown in Hey.com)
    const attachments = document.querySelectorAll('a[href*="/files/"], a[href*="/blobs/"]');

    attachments.forEach(attachment => {
      const wrapper = attachment.closest('div');
      if (!wrapper || wrapper.querySelector('.heydoc-checkbox-overlay')) return;

      // Make wrapper relative for absolute positioning
      wrapper.style.position = 'relative';
      wrapper.classList.add('heydoc-attachment-wrapper');

      // Create checkbox overlay
      const checkbox = document.createElement('div');
      checkbox.className = 'heydoc-checkbox-overlay';
      checkbox.innerHTML = icons.check;

      const fileUrl = attachment.href;
      const fileName = attachment.textContent?.trim() ||
                       fileUrl.split('/').pop()?.split('?')[0] ||
                       'bestand';

      checkbox.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();

        const attachmentData = { url: fileUrl, name: fileName };
        const key = JSON.stringify(attachmentData);

        if (selectedAttachments.has(key)) {
          selectedAttachments.delete(key);
          checkbox.classList.remove('checked');
        } else {
          selectedAttachments.add(key);
          checkbox.classList.add('checked');
        }

        updateFloatingSaveButton();
      });

      wrapper.appendChild(checkbox);
    });
  }

  // Update or show floating save button
  function updateFloatingSaveButton() {
    let floatBtn = document.querySelector('.heydoc-save-float');

    if (selectedAttachments.size === 0) {
      if (floatBtn) floatBtn.remove();
      return;
    }

    if (!floatBtn) {
      floatBtn = document.createElement('div');
      floatBtn.className = 'heydoc-save-float';
      floatBtn.addEventListener('click', () => openModal('document'));
      document.body.appendChild(floatBtn);
    }

    const count = selectedAttachments.size;
    floatBtn.innerHTML = `${icons.doc} ${count} ${count === 1 ? 'bestand' : 'bestanden'} opslaan`;
  }

  // Get email subject from page
  function getEmailSubject() {
    // Hey.com shows subject in h1 or similar
    const subject = document.querySelector('h1')?.textContent?.trim() ||
                    document.querySelector('[class*="subject"]')?.textContent?.trim() ||
                    '';
    return subject;
  }

  // Get email sender
  function getEmailSender() {
    // Look for sender info
    const senderEl = document.querySelector('[class*="from"]') ||
                     document.querySelector('a[href*="mailto:"]');
    return senderEl?.textContent?.trim() || '';
  }

  // Fetch dossiers from API
  async function fetchDossiers(query = '') {
    try {
      const url = query
        ? `${documentorHost}/api/dossiers?q=${encodeURIComponent(query)}`
        : `${documentorHost}/api/dossiers`;

      const response = await fetch(url);
      if (!response.ok) throw new Error('API error');

      return await response.json();
    } catch (error) {
      console.error('HeyDocumentor: Failed to fetch dossiers', error);
      return { matched: null, recent: [], all: [] };
    }
  }

  // Fetch folders for a dossier
  async function fetchFolders(dossierId) {
    try {
      const response = await fetch(`${documentorHost}/api/dossiers/${dossierId}/folders`);
      if (!response.ok) throw new Error('API error');
      const data = await response.json();
      return data.folders || [];
    } catch (error) {
      console.error('HeyDocumentor: Failed to fetch folders', error);
      return [];
    }
  }

  // Open modal
  async function openModal(type) {
    // Remove existing modal
    document.querySelector('.heydoc-modal-overlay')?.remove();

    const subject = getEmailSubject();
    const sender = getEmailSender();

    // Fetch dossiers with smart matching on sender
    const dossierData = await fetchDossiers(sender);

    const overlay = document.createElement('div');
    overlay.className = 'heydoc-modal-overlay';
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });

    let title, bodyContent;

    if (type === 'note') {
      title = 'Notitie maken';
      bodyContent = `
        <div class="heydoc-form-group">
          <label>Titel</label>
          <input type="text" id="heydoc-title" value="${escapeHtml(subject)}">
        </div>
        <div class="heydoc-form-group">
          <label>Inhoud (optioneel)</label>
          <textarea id="heydoc-content" placeholder="Voeg een notitie toe..."></textarea>
        </div>
      `;
    } else if (type === 'action') {
      title = 'Actiepunt maken';
      bodyContent = `
        <div class="heydoc-form-group">
          <label>Beschrijving</label>
          <input type="text" id="heydoc-description" value="${escapeHtml(subject)}">
        </div>
        <div class="heydoc-form-group">
          <label>Deadline (optioneel)</label>
          <input type="date" id="heydoc-due-date">
        </div>
        <div class="heydoc-form-group">
          <label>Herhaling (optioneel)</label>
          <select id="heydoc-recurrence">
            <option value="">Geen herhaling</option>
            <option value="weekly">Wekelijks</option>
            <option value="monthly">Maandelijks</option>
            <option value="quarterly">Elk kwartaal</option>
            <option value="yearly">Jaarlijks</option>
          </select>
        </div>
      `;
    } else {
      // Documents
      const attachments = Array.from(selectedAttachments).map(a => JSON.parse(a));
      const count = attachments.length;
      title = `${count} ${count === 1 ? 'bestand' : 'bestanden'} opslaan`;

      // Create name inputs for each attachment
      const nameInputs = attachments.map((a, i) => `
        <div class="heydoc-form-group">
          <label>Naam ${count > 1 ? (i + 1) : ''}</label>
          <input type="text" class="heydoc-doc-name" data-index="${i}" value="${escapeHtml(a.name)}">
        </div>
      `).join('');

      bodyContent = `
        ${nameInputs}
        <div class="heydoc-form-group">
          <label>Map (optioneel)</label>
          <select id="heydoc-folder" class="heydoc-folder-select" disabled>
            <option value="">Kies eerst een dossier...</option>
          </select>
        </div>
      `;
    }

    overlay.innerHTML = `
      <div class="heydoc-modal">
        <div class="heydoc-modal-header">
          <h2>${title}</h2>
          <button class="heydoc-modal-close">&times;</button>
        </div>
        <div class="heydoc-modal-body">
          ${bodyContent}
          <div class="heydoc-form-group">
            <label>Dossier</label>
            <input type="text" class="heydoc-dossier-search" placeholder="Zoek dossier..." id="heydoc-dossier-search">
            <div class="heydoc-dossier-list" id="heydoc-dossier-list">
              ${renderDossierList(dossierData)}
            </div>
          </div>
        </div>
        <div class="heydoc-modal-footer">
          <button class="heydoc-btn-secondary" id="heydoc-cancel">Annuleren</button>
          <button class="heydoc-btn-primary" id="heydoc-save" disabled>Opslaan</button>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);

    // Event handlers
    overlay.querySelector('.heydoc-modal-close').addEventListener('click', () => overlay.remove());
    overlay.querySelector('#heydoc-cancel').addEventListener('click', () => overlay.remove());

    // Dossier search
    const searchInput = overlay.querySelector('#heydoc-dossier-search');
    const dossierList = overlay.querySelector('#heydoc-dossier-list');
    let selectedDossierId = null;

    searchInput.addEventListener('input', async (e) => {
      const query = e.target.value.trim();
      const newData = await fetchDossiers(query);
      dossierList.innerHTML = renderDossierList(newData);
      bindDossierClicks();
    });

    function bindDossierClicks() {
      dossierList.querySelectorAll('.heydoc-dossier-item').forEach(item => {
        item.addEventListener('click', async () => {
          dossierList.querySelectorAll('.heydoc-dossier-item').forEach(i => i.classList.remove('selected'));
          item.classList.add('selected');
          selectedDossierId = parseInt(item.dataset.id);
          overlay.querySelector('#heydoc-save').disabled = false;

          // Fetch folders for documents
          if (type === 'document') {
            const folderSelect = overlay.querySelector('#heydoc-folder');
            if (folderSelect) {
              folderSelect.innerHTML = '<option value="">Laden...</option>';
              try {
                const folders = await fetchFolders(selectedDossierId);
                folderSelect.innerHTML = '<option value="">Direct in dossier (geen map)</option>' +
                  folders.map(f => `<option value="${f.id}">${escapeHtml(f.name)}</option>`).join('');
                folderSelect.disabled = false;
              } catch (e) {
                folderSelect.innerHTML = '<option value="">Geen mappen beschikbaar</option>';
              }
            }
          }
        });
      });
    }
    bindDossierClicks();

    // Save handler
    overlay.querySelector('#heydoc-save').addEventListener('click', async () => {
      if (!selectedDossierId) return;

      const saveBtn = overlay.querySelector('#heydoc-save');
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<span class="heydoc-loading"></span>';

      try {
        if (type === 'note') {
          await saveNote(selectedDossierId, overlay);
        } else if (type === 'action') {
          await saveActionItem(selectedDossierId, overlay);
        } else {
          await saveDocuments(selectedDossierId, overlay);
        }
        overlay.remove();
      } catch (error) {
        console.error('HeyDocumentor: Save failed', error);
        saveBtn.textContent = 'Fout!';
        saveBtn.disabled = false;
        setTimeout(() => {
          saveBtn.textContent = 'Opslaan';
        }, 2000);
      }
    });
  }

  // Render dossier list HTML with sections
  function renderDossierList(data) {
    const { matched, recent, all } = data;
    let html = '';

    // Matched dossier
    if (matched) {
      html += `
        <div class="heydoc-dossier-item heydoc-dossier-matched" data-id="${matched.id}">
          <div class="name">${escapeHtml(matched.name)}</div>
        </div>
        <div class="heydoc-dossier-divider"></div>
      `;
    }

    // Recent dossiers
    if (recent && recent.length > 0) {
      html += `<div class="heydoc-dossier-header">Recent bijgewerkt</div>`;
      html += recent.map(d => `
        <div class="heydoc-dossier-item" data-id="${d.id}">
          <div class="name">${escapeHtml(d.name)}</div>
        </div>
      `).join('');
      html += `<div class="heydoc-dossier-divider"></div>`;
    }

    // All dossiers
    if (all && all.length > 0) {
      html += `<div class="heydoc-dossier-header">Alle dossiers</div>`;
      html += all.map(d => `
        <div class="heydoc-dossier-item" data-id="${d.id}">
          <div class="name">${escapeHtml(d.name)}</div>
        </div>
      `).join('');
    }

    if (!html) {
      return '<div style="padding: 12px; color: #6b7280; text-align: center;">Geen dossiers gevonden</div>';
    }

    return html;
  }

  // Save note
  async function saveNote(dossierId, overlay) {
    const title = overlay.querySelector('#heydoc-title').value.trim();
    const content = overlay.querySelector('#heydoc-content').value.trim();

    const response = await fetch(`${documentorHost}/api/notes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dossier_id: dossierId,
        title: title || 'Notitie',
        content: content,
        occurred_at: new Date().toISOString()
      })
    });

    if (!response.ok) throw new Error('Failed to save note');
    showNotification('Notitie opgeslagen!');
  }

  // Save action item
  async function saveActionItem(dossierId, overlay) {
    const description = overlay.querySelector('#heydoc-description').value.trim();
    const dueDate = overlay.querySelector('#heydoc-due-date').value;
    const recurrence = overlay.querySelector('#heydoc-recurrence').value;

    const response = await fetch(`${documentorHost}/api/action_items`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dossier_id: dossierId,
        description: description || 'Actiepunt',
        due_date: dueDate || null,
        recurrence: recurrence || null
      })
    });

    if (!response.ok) throw new Error('Failed to save action item');
    showNotification('Actiepunt aangemaakt!');
  }

  // Save documents (attachments)
  async function saveDocuments(dossierId, overlay) {
    const attachments = Array.from(selectedAttachments).map(a => JSON.parse(a));

    // Get custom names from inputs
    const nameInputs = overlay.querySelectorAll('.heydoc-doc-name');
    const customNames = Array.from(nameInputs).map(input => input.value.trim());

    // Get selected folder
    const folderSelect = overlay.querySelector('#heydoc-folder');
    const folderId = folderSelect?.value || null;

    let lastDocUrl = null;

    for (let i = 0; i < attachments.length; i++) {
      const attachment = attachments[i];
      const customName = customNames[i] || attachment.name;

      // Fetch the file
      const fileResponse = await fetch(attachment.url);
      const blob = await fileResponse.blob();

      // Create form data
      const formData = new FormData();
      formData.append('dossier_id', dossierId);
      if (folderId) {
        formData.append('folder_id', folderId);
      }
      formData.append('name', customName);
      formData.append('file', blob, customName);
      formData.append('source_description', 'Via HeyDocumentor vanuit Hey.com');
      formData.append('occurred_at', new Date().toISOString());

      const response = await fetch(`${documentorHost}/api/documents`, {
        method: 'POST',
        body: formData
      });

      if (!response.ok) throw new Error(`Failed to save ${customName}`);

      const result = await response.json();
      lastDocUrl = result.document?.url;
    }

    selectedAttachments.clear();
    updateFloatingSaveButton();

    // Remove checkbox selections
    document.querySelectorAll('.heydoc-checkbox-overlay.checked').forEach(el => {
      el.classList.remove('checked');
    });

    const count = attachments.length;
    const message = `${count} ${count === 1 ? 'bestand' : 'bestanden'} opgeslagen!`;
    showNotification(message, lastDocUrl);
  }

  // Show notification
  function showNotification(message, link = null) {
    const notification = document.createElement('div');
    notification.style.cssText = `
      position: fixed;
      bottom: 24px;
      right: 24px;
      background: #10b981;
      color: white;
      padding: 12px 24px;
      border-radius: 8px;
      font-weight: 500;
      z-index: 10001;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      display: flex;
      align-items: center;
      gap: 12px;
    `;

    notification.innerHTML = `
      <span>${message}</span>
      ${link ? `<a href="${link}" target="_blank" style="color: white; text-decoration: underline; font-weight: 600;">Bekijken &rarr;</a>` : ''}
    `;
    document.body.appendChild(notification);

    setTimeout(() => {
      notification.style.opacity = '0';
      notification.style.transition = 'opacity 0.3s';
      setTimeout(() => notification.remove(), 300);
    }, 4000);
  }

  // Escape HTML
  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  // Start
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
