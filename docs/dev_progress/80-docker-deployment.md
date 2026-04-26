# Docker Deployment Guide

This guide explains how to package and run Hermes Agent using Docker. This is the recommended method for users who want a consistent environment with all dependencies (including Playwright/Browser tools) pre-installed.

## Prerequisites

- [Docker](https://www.docker.com/get-started/) installed and running.
- [Docker Compose](https://docs.docker.com/compose/install/) (usually included with Docker Desktop).
- [Ollama](https://ollama.com/) installed and running on your host machine.

---

## 1. Quick Start

The easiest way to get started is using Docker Compose.

1.  **Build and Start**:
    ```bash
    docker-compose up -d --build
    ```
2.  **Enter Interactive Chat**:
    ```bash
    docker exec -it hermes-agent chat
    ```

---

## 2. Configuration for Ollama

By default, the Docker container is configured to look for Ollama at `http://host.docker.internal:11434/v1`.

### macOS and Windows (Docker Desktop)
This should work out of the box. Ensure Ollama is running on your host machine.

### Linux
Docker Compose uses `extra_hosts: ["host.docker.internal:host-gateway"]` to enable communication with the host. Ensure your host's firewall allows connections from the Docker bridge interface on port 11434.

### Manual Base URL
If your Ollama instance is on a different machine or port, you can override it in `docker-compose.yml` or via command line:
```bash
docker run -it -e HERMES_BASE_URL="http://your-ip:11434/v1" hermes-agent chat
```

---

## 3. Persistent Data

The `docker-compose.yml` file defines a volume named `hermes_data` which maps to `/root/.hermes` inside the container. This ensures that:
- Your `hermes setup` configuration is saved.
- Your conversation history and memory are persisted across container restarts.
- Gateway credentials remain secure and available.

To clear all data and start fresh:
```bash
docker-compose down -v
```

---

## 4. Running Gateways

To run a Hermes Gateway (e.g., Telegram) in the background using Docker:

1.  **Setup (One-time)**:
    ```bash
    docker exec -it hermes-agent gateway setup telegram
    ```
2.  **Start the Service**:
    Update your `docker-compose.yml` or run:
    ```bash
    docker exec -d hermes-agent gateway start telegram
    ```

Alternatively, you can modify the `command` in `docker-compose.yml`:
```yaml
services:
  hermes:
    ...
    command: gateway start telegram
```

---

## 5. Troubleshooting

### Connection Refused
If you see connection errors to Ollama:
1.  **Verify Ollama is running** on the host.
2.  **Check `OLLAMA_HOST`**: On the host machine, ensure Ollama is listening on all interfaces if necessary. For many users, setting `OLLAMA_HOST=0.0.0.0` and restarting Ollama is required.
3.  **Firewall**: Ensure the host firewall isn't blocking port 11434.

### Docker-in-Docker
Some advanced Hermes skills may require Docker to run sandboxed code. Running Docker-in-Docker (DinD) inside this container is not configured by default. If you need this feature, consider mounting the host Docker socket:
```yaml
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```
*Note: This has security implications. Only do this if you trust the agent's tasks.*
