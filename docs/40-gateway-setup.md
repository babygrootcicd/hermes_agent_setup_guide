# Gateway Setup Guide

Gateways allow your Hermes Agent to communicate through external platforms like Telegram, Discord, Slack, and Email.

## Overview

The `hermes gateway` command is used to manage these connections.

- **`hermes gateway setup`**: Interactive setup for various platforms.
- **`hermes gateway start`**: Starts the gateway service.

---

## 1. Telegram Setup

Telegram is one of the easiest gateways to set up.

1.  **Create a Bot**:
    - Message [@BotFather](https://t.me/botfather) on Telegram.
    - Send `/newbot` and follow instructions to get your **Bot API Token**.
2.  **Run Setup**:
    ```bash
    hermes gateway setup telegram
    ```
3.  **Enter Credentials**: Provide the Bot API Token when prompted.
4.  **Start Gateway**:
    ```bash
    hermes gateway start telegram
    ```
5.  **Verify**: Send a message to your bot on Telegram. It should respond using the configured Hermes model.

---

## 2. Discord Setup

1.  **Create an App**:
    - Go to the [Discord Developer Portal](https://discord.com/developers/applications).
    - Click "New Application".
2.  **Create a Bot**:
    - Go to the "Bot" tab and click "Add Bot".
    - Copy the **Bot Token**.
    - Under "Privileged Gateway Intents", enable **MESSAGE CONTENT INTENT**.
3.  **Run Setup**:
    ```bash
    hermes gateway setup discord
    ```
4.  **Enter Credentials**: Provide the Bot Token and Client ID when prompted.
5.  **Invite Bot**: Use the OAuth2 URL generator in the Developer Portal to invite the bot to your server with `Send Messages` permissions.
6.  **Start Gateway**:
    ```bash
    hermes gateway start discord
    ```

---

## 3. Slack Setup

1.  **Create an App**:
    - Go to [api.slack.com/apps](https://api.slack.com/apps) and create a new app "From scratch".
2.  **Configure Scopes**:
    - Go to "OAuth & Permissions" and add `chat:write`, `app_mentions:read`, and `im:history` bot token scopes.
3.  **Install App**: Install the app to your workspace and copy the **Bot User OAuth Token**.
4.  **Run Setup**:
    ```bash
    hermes gateway setup slack
    ```
5.  **Start Gateway**:
    ```bash
    hermes gateway start slack
    ```

---

## 4. Email Setup

Hermes can also interact via Email using IMAP/SMTP.

1.  **Requirements**: An email account with IMAP/SMTP access enabled (e.g., Gmail with App Passwords).
2.  **Run Setup**:
    ```bash
    hermes gateway setup email
    ```
3.  **Enter Credentials**:
    - IMAP Server (e.g., `imap.gmail.com`)
    - SMTP Server (e.g., `smtp.gmail.com`)
    - Email Address and App Password.
4.  **Start Gateway**:
    ```bash
    hermes gateway start email
    ```

---

## Automatic Startup (Systemd / Launchd)

To keep your gateways running in the background:

### macOS (Launchd)
You can create a `.plist` file in `~/Library/LaunchAgents` to manage the `hermes gateway start` command.

### Linux/WSL (Systemd)
Create a service file in `/etc/systemd/system/hermes-gateway.service`:
```ini
[Unit]
Description=Hermes Gateway Service
After=network.target

[Service]
Type=simple
User=yourusername
ExecStart=/home/yourusername/.hermes/bin/hermes gateway start telegram
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## Troubleshooting Gateways

- **Token Errors**: Double-check that your API tokens are correct and have not expired.
- **Connection Issues**: Ensure your machine has internet access and can reach the platform's API endpoints.
- **Permission Denied**: For Discord/Slack, ensure the bot has been granted the necessary scopes/intents in the developer portal.
