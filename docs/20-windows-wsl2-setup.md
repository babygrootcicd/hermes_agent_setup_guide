# Windows/WSL2 Setup Guide

Hermes Agent requires a Linux environment to run effectively. On Windows, this is achieved using **Windows Subsystem for Linux (WSL2)**.

## Prerequisites

- **Windows 10** (version 2004 or higher, Build 19041 or higher) or **Windows 11**.
- **Virtualization** enabled in BIOS/UEFI.
- At least 8GB of RAM (16GB+ recommended).

## Step 1: Install WSL2

If you don't have WSL installed:

1.  Open **PowerShell** as Administrator.
2.  Run the command:
    ```powershell
    wsl --install
    ```
3.  **Restart your computer** when prompted.
4.  After rebooting, a terminal will open to complete the Ubuntu installation. Set your username and password.

## Step 2: Install Ollama (Windows Version)

While you *can* install Ollama inside WSL, it is **highly recommended** to install the Windows version of Ollama for better GPU acceleration support.

1.  Download and install Ollama from [ollama.com/download/windows](https://ollama.com/download/windows).
2.  Launch the Ollama application.
3.  **Configure for WSL access**:
    - By default, Ollama only listens on `localhost`. To allow WSL to talk to it, you need to set an environment variable in Windows.
    - Open **Settings** > **System** > **About** > **Advanced system settings** > **Environment Variables**.
    - Add a new **User variable**:
        - Name: `OLLAMA_HOST`
        - Value: `0.0.0.0`
    - **Restart Ollama** (Quit from system tray and launch again).

## Step 3: Install Hermes Agent (inside WSL)

1.  Open your **WSL Terminal** (e.g., Ubuntu).
2.  Run the official installation script:
    ```bash
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    ```
3.  Add Hermes to your PATH:
    ```bash
    echo 'export PATH="$HOME/.hermes/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    ```

## Step 4: Networking (Connect WSL to Windows Ollama)

Since Hermes is in WSL and Ollama is on Windows, we need the host's IP address.

1.  In your WSL terminal, find your host IP:
    ```bash
    cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
    ```
    *Note: This is usually the IP of your Windows host from WSL's perspective.*

2.  Set the `HERMES_BASE_URL` in your `.bashrc`:
    ```bash
    # Replace <HOST_IP> with the IP found above
    echo 'export HERMES_BASE_URL="http://<HOST_IP>:11434/v1"' >> ~/.bashrc
    source ~/.bashrc
    ```

## Step 5: Verify and Chat

1.  **Pull a model** (on Windows or WSL):
    ```bash
    ollama pull hermes3
    ```
2.  **Start Chatting** (in WSL):
    ```bash
    hermes chat --model hermes3
    ```

## WSL Tips

- **GPU Support**: If you have an NVIDIA GPU, ensure you have the latest [NVIDIA Game Ready](https://www.nvidia.com/Download/index.aspx) or Studio drivers installed on Windows. WSL2 will automatically leverage them.
- **Docker Integration**: If you use Docker Desktop, enable **WSL2 Integration** in Settings > Resources > WSL Integration for your distribution.
- **File Access**: You can access your Windows files from WSL via `/mnt/c/Users/YourName/...`.

## Troubleshooting

- **Connection Refused**: Ensure Windows Firewall is not blocking port 11434. You might need to add an Inbound Rule for it.
- **IP Changes**: The WSL host IP can change after a reboot. Consider using your computer's mDNS name (e.g., `http://your-pc-name.local:11434/v1`) if it resolves correctly.
