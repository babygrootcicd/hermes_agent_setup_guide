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
    let hermesPath = 'hermes';
    
    // Check common installation paths if 'hermes' is not globally available
    const homeDir = app.getPath('home');
    const defaultPath = path.join(homeDir, '.hermes', 'bin', 'hermes');
    
    // We can't easily check for command existence synchronously in cross-platform way without extra libs,
    // but we can try the default path if we are on Unix.
    if (process.platform !== 'win32') {
      const fs = require('fs');
      if (fs.existsSync(defaultPath)) {
        hermesPath = defaultPath;
        console.log(`Using hermes at: ${hermesPath}`);
      }
    }

    hermesProcess = spawn(hermesPath, ['chat']);

    hermesProcess.on('error', (err) => {
      console.error('Failed to start hermes process:', err);
      event.reply('hermes-error', `Failed to start Hermes: ${err.message}. Ensure 'hermes' is in your PATH.`);
      hermesProcess = null;
    });

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
