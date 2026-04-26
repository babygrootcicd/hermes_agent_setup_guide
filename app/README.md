# Hermes Agent GUI

This directory contains an Electron-based desktop application that provides a modern chat interface for the Hermes Agent.

## Development

1.  **Install Dependencies**:
    ```bash
    npm install
    ```
2.  **Run in Development Mode**:
    ```bash
    npm start
    ```

## Packaging (macOS)

To build the standalone `.dmg` installer:
```bash
npm run build
```
The output will be located in the `dist/` directory.

## How it works
The application uses Electron's IPC (Inter-Process Communication) to spawn and communicate with the `hermes chat` CLI process. It automatically looks for the `hermes` binary in your system PATH or the default `~/.hermes/bin/hermes` location.
