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
let catalogBasePath = '';
const EMBEDDED_TASKS = [
    {
        id: 'embedded-daily-briefing',
        title: 'Daily Briefing',
        category: 'Cron Jobs',
        relativePath: 'examples/cron/daily-briefing.yaml',
        preview: 'Daily morning briefing workflow across AI, security, LLM, and scholarship topics.',
    },
    {
        id: 'embedded-disk-monitor',
        title: 'Disk Monitor',
        category: 'Cron Jobs',
        relativePath: 'examples/cron/disk-monitor.yaml',
        preview: 'Every-2-hours disk usage and service uptime checks with alert thresholds.',
    },
    {
        id: 'embedded-nightly-triage',
        title: 'Nightly GitHub Triage',
        category: 'Cron Jobs',
        relativePath: 'examples/cron/nightly-github-triage.yaml',
        preview: 'Nightly PR/CI/CVE audit and prioritized DevSecOps action list.',
    },
    {
        id: 'embedded-weekly-study',
        title: 'Weekly Study Review',
        category: 'Cron Jobs',
        relativePath: 'examples/cron/weekly-study-review.yaml',
        preview: 'Weekly certification study review with domain coverage and drill priorities.',
    },
    {
        id: 'embedded-skill-daily-briefing',
        title: 'Skill: Daily Briefing',
        category: 'Skills',
        relativePath: 'examples/skills/daily-briefing/SKILL.md',
        preview: 'Skill playbook for collecting and delivering daily topic briefings.',
    },
    {
        id: 'embedded-skill-devops-monitor',
        title: 'Skill: DevOps Monitor',
        category: 'Skills',
        relativePath: 'examples/skills/devops-monitor/SKILL.md',
        preview: 'Skill workflow for uptime checks, disk triage, and incident handling.',
    },
    {
        id: 'embedded-skill-pr-review',
        title: 'Skill: GitHub PR Review',
        category: 'Skills',
        relativePath: 'examples/skills/github-pr-review/SKILL.md',
        preview: 'Skill rubric for pull request auditing and risk-driven review outputs.',
    },
    {
        id: 'embedded-template-feature',
        title: 'Template: Feature Implementation',
        category: 'Task Templates',
        relativePath: 'examples/task-templates/feature-implementation.md',
        preview: 'Reusable task template for scoped feature implementation and verification.',
    },
];

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

function renderTaskOptions(tasks) {
    taskSelect.innerHTML = '';
    const grouped = groupTasks(tasks);
    for (const [category, categoryTasks] of grouped.entries()) {
        const optgroup = document.createElement('optgroup');
        optgroup.label = category;
        categoryTasks.forEach((task) => {
            const option = document.createElement('option');
            option.value = task.id;
            option.textContent = task.title;
            optgroup.appendChild(option);
        });
        taskSelect.appendChild(optgroup);
    }
}

function useEmbeddedFallback(reasonText) {
    taskCatalog = EMBEDDED_TASKS.slice();
    catalogBasePath = '';
    renderTaskOptions(taskCatalog);
    taskSelect.value = taskCatalog[0].id;
    updateTaskDetails();
    taskPath.textContent = `${taskPath.textContent} · Embedded presets (${reasonText})`;
}

async function loadTaskCatalog() {
    try {
        const result = await window.api.getTaskCatalog();
        if (!result?.ok) {
            useEmbeddedFallback(`catalog error: ${result?.error || 'unknown error'}`);
            return;
        }

        catalogBasePath = result.repoRoot || '';
        taskCatalog = result.tasks || [];
        if (taskCatalog.length === 0) {
            const source = result.examplesRoot || 'examples/';
            useEmbeddedFallback(`no presets found under ${source}`);
            return;
        }

        renderTaskOptions(taskCatalog);
        taskSelect.value = taskCatalog[0].id;
        updateTaskDetails();
    } catch (err) {
        useEmbeddedFallback(`exception: ${err.message}`);
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
    const targetPath = task.filePath || (catalogBasePath ? `${catalogBasePath}/${task.relativePath}` : task.relativePath);

    const message = [
        `Run this everyday task using the repo example file: ${targetPath}`,
        `Task type: ${task.category}`,
        `Requirements:`,
        `1) Read the file and follow its workflow exactly where possible.`,
        `2) If credentials or integrations are missing, continue in dry-run mode and state what is missing.`,
        `3) Produce actionable output now for today's run.`,
    ].join('\n');

    window.api.sendMessage(message);
});
