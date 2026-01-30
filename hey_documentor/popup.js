const DEFAULT_HOST = 'http://localhost:3000';

document.addEventListener('DOMContentLoaded', async () => {
  const hostInput = document.getElementById('host');
  const saveBtn = document.getElementById('save');
  const testBtn = document.getElementById('test');
  const statusDiv = document.getElementById('status');

  // Load saved host
  const result = await chrome.storage.sync.get(['documentorHost']);
  hostInput.value = result.documentorHost || DEFAULT_HOST;

  // Save host
  saveBtn.addEventListener('click', async () => {
    const host = hostInput.value.trim() || DEFAULT_HOST;
    await chrome.storage.sync.set({ documentorHost: host });
    showStatus('Opgeslagen!', 'success');
  });

  // Test connection
  testBtn.addEventListener('click', async () => {
    const host = hostInput.value.trim() || DEFAULT_HOST;
    try {
      const response = await fetch(`${host}/api/dossiers`);
      if (response.ok) {
        const data = await response.json();
        showStatus(`Verbonden! ${data.dossiers.length} dossiers gevonden.`, 'success');
      } else {
        showStatus(`Fout: HTTP ${response.status}`, 'error');
      }
    } catch (error) {
      showStatus(`Geen verbinding: ${error.message}`, 'error');
    }
  });

  function showStatus(message, type) {
    statusDiv.textContent = message;
    statusDiv.className = `status ${type}`;
    statusDiv.style.display = 'block';
    setTimeout(() => {
      statusDiv.style.display = 'none';
    }, 3000);
  }
});
