const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  sendMessage: (message) => ipcRenderer.send('send-message', message),
  onOutput: (callback) => ipcRenderer.on('hermes-output', (event, data) => callback(data)),
  onError: (callback) => ipcRenderer.on('hermes-error', (event, data) => callback(data)),
  exportLog: () => ipcRenderer.send('export-log')
});
