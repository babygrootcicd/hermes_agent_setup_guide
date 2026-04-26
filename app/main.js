const { app, BrowserWindow, ipcMain, shell } = require('electron');
const path = require('path');
const pty = require('node-pty');
const fs = require('fs');

// --- Logging ---
const logDir = path.join(app.getPath('home'), '.hermes', 'logs');
const logFile = path.join(logDir, 'gui.log');
if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });

function log(message) {
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] ${message}\n`;
  console.log(message);
  fs.appendFileSync(logFile, line);
}

log('--- App Starting ---');

let hermesProcess = null;
let mainWin = null;
let rawOutputLog = '';

function findHermes() {
  const homeDir = app.getPath('home');
  const candidates = [
    path.join(homeDir, '.hermes', 'bin', 'hermes'),
    path.join(homeDir, '.local', 'bin', 'hermes'),
    '/usr/local/bin/hermes',
    '/opt/homebrew/bin/hermes',
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return 'hermes'; // fallback to PATH
}

function spawnHermes(win, cols, rows) {
  if (hermesProcess) return;

  const homeDir = app.getPath('home');
  const hermesPath = findHermes();
  log(`Spawning Hermes from: ${hermesPath}`);

  const spawnEnv = {
    ...process.env,
    PATH: [
      path.join(homeDir, '.hermes', 'bin'),
      path.join(homeDir, '.local', 'bin'),
      '/usr/local/bin',
      '/opt/homebrew/bin',
      process.env.PATH || ''
    ].join(':'),
    TERM: 'xterm-256color',
  };

  try {
    hermesProcess = pty.spawn(hermesPath, ['chat', '-Q', '--accept-hooks', '--yolo'], {
      name: 'xterm-256color',
      cols: cols || 220,
      rows: rows || 50,
      cwd: homeDir,
      env: spawnEnv
    });

    hermesProcess.onData((data) => {
      rawOutputLog += data;
      win.webContents.send('hermes-output', data);
    });

    hermesProcess.onExit(({ exitCode }) => {
      log(`Hermes exited with code ${exitCode}`);
      win.webContents.send('hermes-output', `\r\n[Hermes exited with code ${exitCode}]\r\n`);
      hermesProcess = null;
    });
  } catch (err) {
    log(`CRITICAL ERROR: ${err.message}`);
    win.webContents.send('hermes-error', `Failed to start Hermes: ${err.message}`);
  }
}

function createWindow() {
  log('Creating window...');
  mainWin = new BrowserWindow({
    width: 1000,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  mainWin.loadFile('index.html').catch(e => log(`Failed to load index.html: ${e.message}`));
  mainWin.webContents.openDevTools();
}

app.on('ready', () => {
  log('App ready');
  createWindow();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});

app.on('window-all-closed', () => {
  if (hermesProcess) hermesProcess.kill();
  if (process.platform !== 'darwin') app.quit();
});

app.on('quit', () => {
  if (hermesProcess) hermesProcess.kill();
});

// Renderer signals it's ready — start Hermes
ipcMain.on('renderer-ready', (event, { cols, rows }) => {
  spawnHermes(mainWin, cols, rows);
});

// Raw key data from xterm → PTY stdin
ipcMain.on('write-pty', (event, data) => {
  if (hermesProcess) hermesProcess.write(data);
});

// Terminal resize
ipcMain.on('resize-pty', (event, { cols, rows }) => {
  if (hermesProcess) hermesProcess.resize(cols, rows);
});

// Programmatic message (e.g. Decompose Task button)
ipcMain.on('send-message', (event, message) => {
  if (hermesProcess) {
    log(`Sending message: ${message}`);
    hermesProcess.write(message + '\r');
  }
});

// Export raw PTY log
ipcMain.on('export-log', () => {
  const exportPath = path.join(app.getPath('home'), '.hermes', 'logs', 'raw-chat.log');
  fs.writeFileSync(exportPath, rawOutputLog);
  log(`Raw log exported to ${exportPath}`);
  shell.showItemInFolder(exportPath);
});
