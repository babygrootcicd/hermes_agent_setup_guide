const chatForm = document.getElementById('chat-form');
const messageInput = document.getElementById('message-input');
const messagesContainer = document.getElementById('messages');
const statusDisplay = document.getElementById('status');

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

let currentHermesMessage = null;

window.api.onOutput((data) => {
    statusDisplay.textContent = 'Hermes is thinking...';
    
    if (!currentHermesMessage) {
        currentHermesMessage = document.createElement('div');
        currentHermesMessage.classList.add('message', 'hermes-message');
        messagesContainer.appendChild(currentHermesMessage);
    }
    
    currentHermesMessage.textContent += data;
    
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
