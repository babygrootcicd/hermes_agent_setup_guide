const chatForm = document.getElementById('chat-form');
const messageInput = document.getElementById('message-input');
const messagesContainer = document.getElementById('messages');
const statusDisplay = document.getElementById('status');
const decomposeBtn = document.getElementById('decompose-btn');

decomposeBtn.addEventListener('click', () => {
    const currentInput = messageInput.value.trim();
    messageInput.value = `Please decompose this task into manageable sub-tasks: ${currentInput}`;
    messageInput.focus();
});

function addMessage(text, type) {
    const messageDiv = document.createElement('div');
    messageDiv.classList.add('message', `${type}-message`);
    messageDiv.textContent = text;
    messagesContainer.appendChild(messageDiv);
    
    // Auto scroll to bottom
    const main = document.querySelector('main');
    main.scrollTop = main.scrollHeight;
}

chatForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const message = messageInput.value.trim();
    if (message) {
        addMessage(message, 'user');
        window.api.sendMessage(message);
        messageInput.value = '';
        // Reset current hermes message so the next output starts in a new box
        currentHermesMessage = null;
        statusDisplay.textContent = 'Waiting for Hermes...';
    }
});

// Buffer raw PTY bytes so escape sequences aren't split across chunks before stripping
let rawSeqBuffer = '';

function stripAnsi(str) {
    return str
        // CSI: ESC [ <param bytes 0x20-0x3F>* <final byte 0x40-0x7E>
        // Covers standard (\x1B[31m), DEC private (\x1B[?25h), etc.
        .replace(/\x1B\[[\x20-\x3F]*[\x40-\x7E]/g, '')
        // OSC: ESC ] ... ST(BEL or ESC\)
        .replace(/\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)/g, '')
        // Other two-byte Fe escapes
        .replace(/\x1B[@-Z\\-_]/g, '')
        // Remaining lone ESC
        .replace(/\x1B/g, '')
        // Non-printable control chars (keep \n \r \t)
        .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
}

function flushRaw(incoming) {
    rawSeqBuffer += incoming;
    // Hold back if buffer ends mid-escape-sequence (ESC seen but sequence not closed)
    const incompleteEsc = /\x1B(?:\[[\x20-\x3F]*)?$/.test(rawSeqBuffer);
    if (incompleteEsc) return '';
    const out = stripAnsi(rawSeqBuffer);
    rawSeqBuffer = '';
    return out;
}

let currentHermesMessage = null;
let hermesBuffer = '';

window.api.onOutput((data) => {
    statusDisplay.textContent = 'Hermes is thinking...';

    const clean = flushRaw(data);
    if (!clean) return;

    hermesBuffer += clean;

    // Flush complete lines; hold the last incomplete line in the buffer
    const lines = hermesBuffer.split(/\r?\n/);
    hermesBuffer = lines.pop();

    const toAppend = lines.join('\n') + (lines.length > 0 ? '\n' : '');
    if (!toAppend) return;

    if (!currentHermesMessage) {
        currentHermesMessage = document.createElement('div');
        currentHermesMessage.classList.add('message', 'hermes-message');
        messagesContainer.appendChild(currentHermesMessage);
    }

    currentHermesMessage.textContent += toAppend;

    const main = document.querySelector('main');
    main.scrollTop = main.scrollHeight;
});

// Export raw log
document.getElementById('export-btn').addEventListener('click', () => {
    window.api.exportLog();
});

window.api.onError((data) => {
    console.error('Hermes Error:', data);
    statusDisplay.textContent = 'Error occurred';
    addMessage(`Error: ${data}`, 'hermes');
});

// Initial status
statusDisplay.textContent = 'Ready';
