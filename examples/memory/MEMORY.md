<!-- HERMES AGENT — MEMORY.md TEMPLATE
     Copy to: ~/.hermes/memories/MEMORY.md
     Capacity limit: ~2,200 characters (Hermes loads this into every session prompt)
     Keep entries SHORT. One line per fact. Delete what you don't need.
     Hermes writes here automatically; you can also edit directly.
-->

## Environment
<!-- OS, shell, local tooling. One line each. -->
- OS: [e.g. macOS 14 Sonoma / Ubuntu 24.04]
- Shell: [e.g. zsh with Oh My Zsh]
- Container runtime: [e.g. Docker Desktop 4.x / Podman]
- Editor: [e.g. Cursor + VS Code]
- Package managers: [e.g. brew, npm, pip, go modules]

## Active Projects
<!-- Name, short stack, repo location. -->
- [project-name]: [e.g. Next.js 14 + Go 1.22 API + PostgreSQL] — ~/projects/[name]
- [project-name]: [e.g. Prometheus + Grafana + Loki monitoring stack] — ~/projects/[name]

## Infrastructure
<!-- Servers, ports, service names. NO passwords or tokens here. -->
- [server-alias]: [OS] @ [hostname/IP] — runs [services]
- Key ports: [service]:[port], [service]:[port]
- Storage: [e.g. MinIO on minio.internal:9000]

## Tool Quirks & Workarounds
<!-- Things the agent must know to avoid mistakes. -->
- [e.g. Do not use sudo docker — user is already in docker group]
- [e.g. GitLab runner cache invalidates on branch rename; always re-trigger after rename]

## Completed Work
<!-- Date + what was done. Helps avoid re-doing finished tasks. -->
- [YYYY-MM-DD]: [e.g. Migrated Loki from BoltDB to TSDB backend]
- [YYYY-MM-DD]: [e.g. Set up GitHub Actions matrix for go test across 3 OS targets]

## Project Conventions
<!-- Commit style, PR rules, naming patterns. -->
- Commits: [e.g. conventional commits — feat/fix/chore/docs/refactor]
- PRs: [e.g. squash merge only; require 1 approval]
- Branch naming: [e.g. feat/TICKET-description]

## Corrections
<!-- Things the agent got wrong; add so it won't repeat. -->
- [e.g. Alert threshold is 85%, not 80% — confirmed by ops team 2025-03-10]

## Known Pitfalls
<!-- Hard rules / things to never do. -->
- [e.g. Never run db migrations on prod without a snapshot backup first]
- [e.g. Do not commit .env files — secrets via environment injection only]
