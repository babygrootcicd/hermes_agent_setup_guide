# Fix Progress: posix_spawnp failed

## Root Cause

`node-pty` is a native C++ addon that must be compiled against Electron's specific ABI — not the system Node.js runtime. The `app/node_modules/node-pty/build/Release/` directory did not exist, meaning the native `.node` binary was never built. Every call to `pty.spawn()` threw `posix_spawnp failed`.

A secondary issue: when the packaged app is launched from the DMG (outside Terminal), `process.env` does not include the user's shell PATH customizations, so `~/.hermes/bin/hermes` was never found via the PATH fallback.

---

## Fixes Applied

- [x] **Fix 1** — `scripts/macos/build_app.sh`
  - **What**: Replaced fragile `--version`-check rebuild logic with a direct unconditional call: `npx @electron/rebuild -f -w node-pty`
  - **Why**: The version checks silently fell through to a no-op warning, leaving `node-pty` unbuilt and causing the crash.

- [x] **Fix 2** — `app/main.js`
  - **What**: Before `pty.spawn`, construct a `spawnEnv` that prepends `~/.hermes/bin`, `~/.local/bin`, `/usr/local/bin`, and `/opt/homebrew/bin` to `PATH`, then pass `env: spawnEnv` to the spawn call.
  - **Why**: Apps launched from the DMG (outside Terminal) inherit a minimal `PATH` with no shell profile customizations, so `hermes` is never found via the PATH fallback.

- [x] **Fix 3** — `scripts/macos/debug.sh`
  - **What**: Fixed `open -a dist/Hermes Agent-xxx.dmg` → `open "dist/Hermes Agent-0.1.0-arm64.dmg"`. Reordered script so `open` runs before `tail -f` (tail blocks execution).
  - **Why**: `open -a` is for `.app` bundles in `/Applications`, not DMG files. The placeholder `xxx` was never a real path. The original order meant the app never launched.

- [x] **Fix 4** — `app/package.json`
  - **What**: Added `"node_modules/node-pty/build/Release/**"` to the `build.files` array.
  - **Why**: electron-builder may strip native `.node` binaries from packaging. Explicit inclusion ensures `pty.node` and `spawn-helper` survive into the final `.app` bundle.

---

## How to Rebuild and Test

```bash
cd app
npm install
npx @electron/rebuild -f -w node-pty
npm run build
```

Then mount the DMG from `app/dist/` and launch the app. Sending a message should no longer show the `posix_spawnp failed` error.
