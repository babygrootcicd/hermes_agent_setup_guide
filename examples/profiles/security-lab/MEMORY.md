# Agent Memory — security-lab profile

## Infrastructure
- Server OS: Ubuntu 24.04
- GitLab: https://gitlab.internal
- MinIO: http://minio.internal:9000
- Prometheus: http://prometheus.internal:9090
- Grafana: http://grafana.internal:3000
- Loki: http://loki.internal:3100

## Operations
- Alert threshold: 85% disk usage triggers cleanup plan
- Backup path: /var/opt/gitlab/backups
- Do not use sudo docker: user is in docker group

## Security Rules
- Never store credentials, tokens, or private keys in memory files
- Keep incident notes sanitized before sharing outside this profile
