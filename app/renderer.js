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
    }
});

let currentHermesMessage = null;

window.api.onOutput((data) => {
    statusDisplay.textContent = 'Hermes is thinking...';
    
    // For terminal-like streaming, we append to the last message if it's from Hermes
    // But since Hermes output can be complex, for this scaffold we'll just append.
    // In a more advanced version, we might want to handle chunks better.
    
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
    // Optionally display errors in the UI
});

// Initial status
statusDisplay.textContent = 'Ready';
