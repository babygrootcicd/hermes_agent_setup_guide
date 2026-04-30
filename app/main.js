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
let repoRoot = '';
let examplesRoot = '';

function isTextFile(name) {
  return ['.md', '.yaml', '.yml', '.txt'].includes(path.extname(name).toLowerCase());
}

function humanizeSlug(input) {
  return input
    .replace(/\.[^.]+$/, '')
    .replace(/[-_]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function readPreview(filePath, maxLines = 8, maxChars = 700) {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    const lines = raw.split(/\r?\n/).slice(0, maxLines).join('\n');
    return lines.slice(0, maxChars);
  } catch {
    return '';
  }
}

function walkFiles(dirPath, acc = []) {
  if (!fs.existsSync(dirPath)) return acc;
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      walkFiles(fullPath, acc);
      continue;
    }
    if (entry.isFile()) acc.push(fullPath);
  }
  return acc;
}

function hasExamplesDir(root) {
  return !!root && fs.existsSync(path.join(root, 'examples'));
}

function resolveRepoRoot() {
  const homeDir = app.getPath('home');
  const candidates = [
    process.env.HERMES_SETUP_GUIDE_ROOT,
    process.cwd(),
    path.resolve(__dirname, '..'),
    path.resolve(__dirname, '../..'),
    path.join(homeDir, 'Documents', 'GitHub', 'hermes_agent_setup_guide'),
    path.join(homeDir, 'Desktop', 'hermes_agent_setup_guide'),
  ].filter(Boolean);

  for (const candidate of candidates) {
    const normalized = path.resolve(candidate);
    if (hasExamplesDir(normalized)) return normalized;
  }

  return path.resolve(__dirname, '..');
}

function resolvePaths() {
  repoRoot = resolveRepoRoot();
  examplesRoot = path.join(repoRoot, 'examples');
  return { repoRoot, examplesRoot };
}

function discoverTaskPresets() {
  const resolved = resolvePaths();
  const root = resolved.repoRoot;
  const examples = resolved.examplesRoot;
  const tasks = [];
  if (!fs.existsSync(examples)) return tasks;

  const cronDir = path.join(examples, 'cron');
  const skillsDir = path.join(examples, 'skills');
  const templatesDir = path.join(examples, 'task-templates');

  if (fs.existsSync(cronDir)) {
    for (const fullPath of walkFiles(cronDir)) {
      const rel = path.relative(root, fullPath);
      const base = path.basename(fullPath);
      if (!isTextFile(base)) continue;
      const category = rel.includes(`${path.sep}prompts${path.sep}`) ? 'Cron Prompts' : 'Cron Jobs';
      tasks.push({
        id: rel.replace(/[^a-zA-Z0-9]+/g, '-').toLowerCase(),
        title: humanizeSlug(base),
        category,
        filePath: fullPath,
        relativePath: rel,
        preview: readPreview(fullPath),
      });
    }
  }

  if (fs.existsSync(skillsDir)) {
    for (const fullPath of walkFiles(skillsDir)) {
      const rel = path.relative(root, fullPath);
      const base = path.basename(fullPath);
      if (base !== 'SKILL.md') continue;
      const skillName = path.basename(path.dirname(fullPath));
      tasks.push({
        id: rel.replace(/[^a-zA-Z0-9]+/g, '-').toLowerCase(),
        title: humanizeSlug(skillName),
        category: 'Skills',
        filePath: fullPath,
        relativePath: rel,
        preview: readPreview(fullPath),
      });
    }
  }

  if (fs.existsSync(templatesDir)) {
    for (const fullPath of walkFiles(templatesDir)) {
      const rel = path.relative(root, fullPath);
      const base = path.basename(fullPath);
      if (!isTextFile(base)) continue;
      tasks.push({
        id: rel.replace(/[^a-zA-Z0-9]+/g, '-').toLowerCase(),
        title: humanizeSlug(base),
        category: 'Task Templates',
        filePath: fullPath,
        relativePath: rel,
        preview: readPreview(fullPath),
      });
    }
  }

  return tasks.sort((a, b) => {
    if (a.category === b.category) return a.title.localeCompare(b.title);
    return a.category.localeCompare(b.category);
  });
}

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
    hermesProcess = pty.spawn(hermesPath, ['chat', '--toolsets', 'terminal,skills', '--max-turns', '20'], {
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

ipcMain.handle('get-task-catalog', () => {
  try {
    const tasks = discoverTaskPresets();
    return { ok: true, repoRoot, examplesRoot, tasks };
  } catch (err) {
    log(`Task catalog error: ${err.message}`);
    return { ok: false, error: err.message, tasks: [] };
  }
});

// Export raw PTY log
ipcMain.on('export-log', () => {
  const exportPath = path.join(app.getPath('home'), '.hermes', 'logs', 'raw-chat.log');
  fs.writeFileSync(exportPath, rawOutputLog);
  log(`Raw log exported to ${exportPath}`);
  shell.showItemInFolder(exportPath);
});
