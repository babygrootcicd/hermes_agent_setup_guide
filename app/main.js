const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

function createWindow() {
  const win = new BrowserWindow({
    width: 1000,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  win.loadFile('index.html');
  // win.webContents.openDevTools();
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (hermesProcess) {
    hermesProcess.kill();
  }
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('quit', () => {
  if (hermesProcess) {
    hermesProcess.kill();
  }
});

let hermesProcess = null;

ipcMain.on('send-message', (event, message) => {
  if (!hermesProcess) {
    // Start hermes chat if not already running
    // We assume 'hermes' is in the PATH or we need to find it.
    // For this prototype, we'll try 'hermes chat'
    hermesProcess = spawn('hermes', ['chat']);

    hermesProcess.stdout.on('data', (data) => {
      event.reply('hermes-output', data.toString());
    });

    hermesProcess.stderr.on('data', (data) => {
      event.reply('hermes-error', data.toString());
    });

    hermesProcess.on('close', (code) => {
      event.reply('hermes-output', `\n[Hermes exited with code ${code}]\n`);
      hermesProcess = null;
    });
  }

  // Send the user message to hermes stdin
  if (hermesProcess && hermesProcess.stdin) {
    hermesProcess.stdin.write(message + '\n');
  }
});
