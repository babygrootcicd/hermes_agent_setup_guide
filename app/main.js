const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const pty = require('node-pty');
const fs = require('fs');

// --- Logging Utility ---
const logDir = path.join(app.getPath('home'), '.hermes', 'logs');
const logFile = path.join(logDir, 'gui.log');

if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

function log(message) {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] ${message}\n`;
  console.log(message);
  fs.appendFileSync(logFile, logMessage);
}

log('--- App Starting ---');

let hermesProcess = null;

function createWindow() {
  log('Creating window...');
  const win = new BrowserWindow({
    width: 1000,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  win.loadFile('index.html').catch(e => log(`Failed to load index.html: ${e.message}`));
  // win.webContents.openDevTools();
}

app.on('ready', () => {
  log('App ready');
  createWindow();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
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

ipcMain.on('send-message', (event, message) => {
  if (!hermesProcess) {
    let hermesPath = 'hermes';
    
    // Potential paths to search
    const homeDir = app.getPath('home');
    const searchPaths = [
      path.join(homeDir, '.local', 'bin', 'hermes'),
      path.join(homeDir, '.hermes', 'bin', 'hermes'),
      '/usr/local/bin/hermes',
      '/opt/homebrew/bin/hermes',
      'hermes' // Fallback to PATH
    ];

    for (const p of searchPaths) {
      if (p === 'hermes') {
        hermesPath = p;
        break;
      }
      if (fs.existsSync(p)) {
        hermesPath = p;
        break;
      }
    }

    log(`Spawning Hermes in PTY from: ${hermesPath}`);
    
    // Use node-pty to provide a real TTY environment
    try {
      const spawnEnv = {
        ...process.env,
        PATH: [
          path.join(homeDir, '.hermes', 'bin'),
          path.join(homeDir, '.local', 'bin'),
          '/usr/local/bin',
          '/opt/homebrew/bin',
          process.env.PATH || ''
        ].join(':')
      };

      // Use bash -c to ensure the script and its virtualenv are handled correctly
      hermesProcess = pty.spawn('/bin/bash', ['-c', `${hermesPath} chat -Q --accept-hooks --yolo`], {
        name: 'xterm-color',
        cols: 80,
        rows: 30,
        cwd: process.cwd(),
        env: spawnEnv
      });

      hermesProcess.onData((data) => {
        event.reply('hermes-output', data);
      });

      hermesProcess.onExit(({ exitCode, signal }) => {
        log(`Hermes process exited with code ${exitCode}`);
        event.reply('hermes-output', `\n[Hermes exited with code ${exitCode}]\n`);
        hermesProcess = null;
      });
    } catch (err) {
      log(`CRITICAL ERROR: Failed to spawn pty: ${err.message}`);
      event.reply('hermes-error', `Failed to start Hermes: ${err.message}`);
    }
  }

  // Send the user message to hermes stdin via PTY
  if (hermesProcess) {
    log(`Sending message to Hermes: ${message}`);
    hermesProcess.write(message + '\r'); // Use \r for PTY input
  }
});
