const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  rendererReady: (cols, rows) => ipcRenderer.send('renderer-ready', { cols, rows }),
  writeKey:      (data)       => ipcRenderer.send('write-pty', data),
  resize:        (cols, rows) => ipcRenderer.send('resize-pty', { cols, rows }),
  sendMessage:   (message)    => ipcRenderer.send('send-message', message),
  exportLog:     ()           => ipcRenderer.send('export-log'),
  getTaskCatalog: ()          => ipcRenderer.invoke('get-task-catalog'),
  onOutput: (callback) => ipcRenderer.on('hermes-output', (event, data) => callback(data)),
  onError:  (callback) => ipcRenderer.on('hermes-error',  (event, data) => callback(data)),
});
