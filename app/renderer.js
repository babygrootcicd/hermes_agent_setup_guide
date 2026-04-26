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

// Strip ANSI escape codes (colors, cursor moves, etc.) from PTY output
function stripAnsi(str) {
    return str.replace(/\x1B\[[0-9;]*[A-Za-z]/g, '')  // CSI sequences
              .replace(/\x1B\][^\x07]*\x07/g, '')       // OSC sequences
              .replace(/\x1B[()][AB012]/g, '')           // character set
              .replace(/\x1B[@-Z\\-_]/g, '')             // two-byte escapes
              .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, ''); // control chars except \n \r \t
}

let currentHermesMessage = null;
let hermesBuffer = '';

window.api.onOutput((data) => {
    statusDisplay.textContent = 'Hermes is thinking...';

    hermesBuffer += stripAnsi(data);

    // Flush complete lines; hold the last incomplete line in the buffer
    const lines = hermesBuffer.split(/\r?\n/);
    hermesBuffer = lines.pop(); // last element may be incomplete

    const toAppend = lines.join('\n') + (lines.length > 0 ? '\n' : '');
    if (!toAppend) return;

    if (!currentHermesMessage) {
        currentHermesMessage = document.createElement('div');
        currentHermesMessage.classList.add('message', 'hermes-message');
        messagesContainer.appendChild(currentHermesMessage);
    }

    currentHermesMessage.textContent += toAppend;

    // Auto scroll to bottom
    const main = document.querySelector('main');
    main.scrollTop = main.scrollHeight;
});

window.api.onError((data) => {
    console.error('Hermes Error:', data);
    statusDisplay.textContent = 'Error occurred';
    addMessage(`Error: ${data}`, 'hermes');
});

// Initial status
statusDisplay.textContent = 'Ready';
