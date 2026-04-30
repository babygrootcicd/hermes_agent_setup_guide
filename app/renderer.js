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
const taskSelect     = document.getElementById('task-select');
const taskPreview    = document.getElementById('task-preview');
const taskPath       = document.getElementById('task-path');
const runTaskBtn     = document.getElementById('run-task-btn');
let taskCatalog = [];

// Calculate cols/rows from container pixel size
function calcSize() {
    const w = termContainer.clientWidth  || 700;
    const h = termContainer.clientHeight || 600;
    // xterm default cell: ~8.4px wide, ~17px tall at 13px font
    const cols = Math.max(80,  Math.floor(w / 8.4));
    const rows = Math.max(24, Math.floor(h / 17));
    return { cols, rows };
}

function updateTaskDetails() {
    const selectedId = taskSelect.value;
    const task = taskCatalog.find((t) => t.id === selectedId);
    if (!task) {
        taskPreview.value = '';
        taskPath.textContent = 'No preset selected';
        runTaskBtn.disabled = true;
        return;
    }
    const preview = task.preview || '(No preview available)';
    taskPreview.value = preview;
    taskPath.textContent = `${task.category} · ${task.relativePath}`;
    runTaskBtn.disabled = false;
}

function groupTasks(tasks) {
    const grouped = new Map();
    tasks.forEach((task) => {
        if (!grouped.has(task.category)) grouped.set(task.category, []);
        grouped.get(task.category).push(task);
    });
    return grouped;
}

async function loadTaskCatalog() {
    try {
        const result = await window.api.getTaskCatalog();
        if (!result?.ok) {
            taskSelect.innerHTML = '<option value="">No presets available</option>';
            taskPath.textContent = `Failed to load presets: ${result?.error || 'unknown error'}`;
            runTaskBtn.disabled = true;
            return;
        }

        taskCatalog = result.tasks || [];
        if (taskCatalog.length === 0) {
            taskSelect.innerHTML = '<option value="">No presets found</option>';
            const source = result.examplesRoot || 'examples/';
            taskPath.textContent = `No task presets found under: ${source}`;
            runTaskBtn.disabled = true;
            return;
        }

        taskSelect.innerHTML = '';
        const grouped = groupTasks(taskCatalog);
        for (const [category, tasks] of grouped.entries()) {
            const optgroup = document.createElement('optgroup');
            optgroup.label = category;
            tasks.forEach((task) => {
                const option = document.createElement('option');
                option.value = task.id;
                option.textContent = task.title;
                optgroup.appendChild(option);
            });
            taskSelect.appendChild(optgroup);
        }

        taskSelect.value = taskCatalog[0].id;
        updateTaskDetails();
    } catch (err) {
        taskPath.textContent = `Failed to load presets: ${err.message}`;
        runTaskBtn.disabled = true;
    }
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

loadTaskCatalog();

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

taskSelect.addEventListener('change', updateTaskDetails);

runTaskBtn.addEventListener('click', () => {
    const selectedId = taskSelect.value;
    const task = taskCatalog.find((t) => t.id === selectedId);
    if (!task) return;

    const message = [
        `Run this everyday task using the repo example file: ${task.filePath}`,
        `Task type: ${task.category}`,
        `Requirements:`,
        `1) Read the file and follow its workflow exactly where possible.`,
        `2) If credentials or integrations are missing, continue in dry-run mode and state what is missing.`,
        `3) Produce actionable output now for today's run.`,
    ].join('\n');

    window.api.sendMessage(message);
});
