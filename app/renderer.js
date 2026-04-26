if (typeof Terminal === 'undefined') {
    document.getElementById('terminal').textContent = 'ERROR: xterm.js failed to load. Run: npm install';
    throw new Error('xterm Terminal not defined — run npm install in the app/ directory');
}

const term = new Terminal({
    cursorBlink: true,
    fontSize: 13,
    fontFamily: 'Menlo, Monaco, "Courier New", monospace',
    allowTransparency: false,
    theme: {
        background: '#1a1a1a',
        foreground: '#d4d4d4',
        cursor: '#00ff9d',
        selectionBackground: '#00ff9d44',
    }
});

const termContainer = document.getElementById('terminal');
term.open(termContainer);

const statusDisplay  = document.getElementById('status');
const exportBtn      = document.getElementById('export-btn');
const decomposeBtn   = document.getElementById('decompose-btn');
const decomposeInput = document.getElementById('decompose-input');

// Calculate cols/rows from container pixel size
function calcSize() {
    const w = termContainer.clientWidth  || 800;
    const h = termContainer.clientHeight || 600;
    // xterm default cell: ~8.4px wide, ~17px tall at 13px font
    const cols = Math.max(80,  Math.floor(w / 8.4));
    const rows = Math.max(24, Math.floor(h / 17));
    return { cols, rows };
}

// Initial resize then tell main process to start Hermes
function init() {
    const { cols, rows } = calcSize();
    term.resize(cols, rows);
    window.api.rendererReady(cols, rows);
    statusDisplay.textContent = 'Connecting...';
}

// Wait for the container to have real dimensions
if (termContainer.clientWidth > 0) {
    init();
} else {
    requestAnimationFrame(init);
}

// PTY output → xterm
window.api.onOutput((data) => {
    statusDisplay.textContent = 'Hermes is running';
    term.write(data);
});

window.api.onError((data) => {
    statusDisplay.textContent = 'Error';
    term.write(`\r\nError: ${data}\r\n`);
});

// xterm keyboard input → PTY stdin
term.onData((data) => {
    window.api.writeKey(data);
});

// Window resize → sync PTY size
window.addEventListener('resize', () => {
    const { cols, rows } = calcSize();
    term.resize(cols, rows);
    window.api.resize(cols, rows);
});

// Export raw log
exportBtn.addEventListener('click', () => {
    window.api.exportLog();
});

// Decompose task — inject text into the live terminal
decomposeBtn.addEventListener('click', () => {
    const text = decomposeInput.value.trim();
    if (text) {
        window.api.sendMessage(`Please decompose this task into manageable sub-tasks: ${text}`);
        decomposeInput.value = '';
    }
});
