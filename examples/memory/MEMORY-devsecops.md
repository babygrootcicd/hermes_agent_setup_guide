## Environment
- OS: macOS 14.5 Sonoma, zsh, Homebrew
- Docker: Docker Desktop 4.29; user in docker group — never sudo docker
- Editor: Cursor + VS Code; terminal: iTerm2

## Active Projects
- pandora-box-console: Next.js 14 + Go 1.22 API + PostgreSQL 16 — ~/projects/pandora-box-console
- lab-monitor: Prometheus + Grafana + Loki + Alertmanager — ~/projects/lab-monitor

## Infrastructure
- lab-srv-01: Ubuntu 24.04 @ 192.168.1.10 — GitLab CE, MinIO, Docker
- Ports: GitLab:80/443, MinIO:9000, Prometheus:9090, Grafana:3000, Loki:3100
- GitLab backups: /var/opt/gitlab/backups (check weekly)

## Tool Quirks & Workarounds
- Never sudo docker — user is in docker group; sudo breaks socket permissions
- GitLab runner cache invalidates silently on branch rename; re-trigger pipeline after any rename
- MinIO SDK v7 breaks on path-style URLs; always use virtual-hosted-style

## Completed Work
- 2026-04-10: Migrated Loki storage from BoltDB to TSDB; retention set to 30d
- 2026-04-18: Added Alertmanager → Telegram webhook for disk >85% alerts
- 2026-04-25: Set up GitHub Actions matrix for go test (linux/mac/windows)

## Conventions
- Commits: conventional commits (feat/fix/chore/docs/refactor/ci)
- PRs: squash merge; 1 approval required; no direct push to main
- Env vars: inject via .env.local; never commit secrets

## Corrections
- Disk alert threshold is 85%, not 80% — confirmed ops 2026-04-01
- Grafana admin password rotated 2026-03-15; old value in docs is stale

## Known Pitfalls
- Never run db migrations without pg_dump snapshot first
- GitLab upgrade: always backup before; runner tokens reset after major version
