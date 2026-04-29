# Skill: GitHub PR Review

## Metadata
- **Version:** 1.0.0
- **Compatible with:** Hermes Agent 0.x+
- **Standard:** agentskills.io/v1

## Triggers
Invoke this skill when the user says any of:
- "review PR #N"
- "PR audit"
- "pull request review"
- "check this PR"
- "review open PRs"
- "nightly PR triage"

---

## Tools Required
| Tool | Purpose |
|------|---------|
| `github` | Fetch PR diff, CI status, comments, labels, changed files list |
| `terminal` | Run local linting or static analysis if `--workdir` is set |
| `file` | Read project-specific review rubric from AGENTS.md / .cursorrules |
| `memory` | Read repo conventions from MEMORY.md |
| `web` | Look up CVE details for flagged dependencies |

---

## Customization Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PR_REPO` | From MEMORY.md | `owner/repo` format |
| `PR_NUMBER` | Required or `--all-open` | Specific PR or batch mode |
| `PR_MAX_DIFF_LINES` | `500` | Above this, switch to summary mode |
| `PR_REQUIRE_TESTS` | `true` | Flag PRs with changed logic but no test changes |
| `PR_SECURITY_SCAN` | `true` | Check for security-relevant patterns |
| `PR_CHECK_DOCS` | `true` | Flag if public API changed but docs not updated |
| `PR_DELIVERY` | `github_comment` | Where to post: `github_comment`, `telegram`, `file` |
| `PR_LANGUAGE` | `en` | Review output language |

---

## Step-by-Step Procedure

### Step 1: Load context
```
Read from MEMORY.md:
- Repo name, branch convention, commit message style
- Known CI failure patterns
- Security audit checklist for this repo
- PR merge strategy (squash / merge / rebase)

Read from AGENTS.md or .cursorrules (if present in --workdir):
- Code style rules
- Review rubric specifics
```

### Step 2: Fetch PR data
```
github.get_pull_request(repo=PR_REPO, pr=PR_NUMBER)
→ title, description, author, base branch, head branch, labels, milestone

github.get_pull_request_diff(repo=PR_REPO, pr=PR_NUMBER)
→ changed files list, diff content

github.get_check_runs(repo=PR_REPO, ref=PR_HEAD_SHA)
→ CI status per job: passed / failed / pending

github.list_pull_request_comments(repo=PR_REPO, pr=PR_NUMBER)
→ existing review comments (to avoid duplication)
```

### Step 3: Assess PR size
- **Small** (< 100 diff lines): Full line-by-line review
- **Medium** (100–500 lines): Review by file/section; flag highest-risk areas
- **Large** (> 500 lines): Summary mode — identify changed components, flag risks, note inability to do full review; recommend splitting

### Step 4: Apply review rubric

For each changed file, check:

| Category | Check |
|----------|-------|
| **Code style** | Follows project conventions (naming, formatting, comment style) |
| **Test coverage** | Changed logic has corresponding test changes; no test deletion without reason |
| **Security** | No hardcoded secrets; no unsafe deserialization; no SQL string concat; no new eval/exec; auth/authz not weakened; input validation at boundaries |
| **Breaking changes** | Public API signatures changed; database schema migration needed; config keys renamed |
| **Error handling** | Errors are handled or propagated, not swallowed |
| **Dependencies** | New packages added; version pinned; license compatible; no known CVEs |
| **Docs** | Public API, CLI flags, or config changed → docs/CHANGELOG updated |
| **CI status** | All checks pass; failing checks understood and explained |

**Security scan patterns to check:**
```
- Hardcoded secrets: /api.key|secret|password|token\s*=\s*["'][^"']+["']/i
- SQL injection: string concatenation in SQL queries
- Command injection: os.exec / subprocess with user input
- Path traversal: file operations with user-supplied paths
- Insecure deserialisation: pickle.loads, yaml.load (without Loader)
- Exposed internal endpoints in newly added routes
```

### Step 5: Compose review output

**Output format:**

```markdown
## PR Review: #{PR_NUMBER} — {PR_TITLE}

### Summary
{1–3 sentence overview of what this PR does and overall assessment}

**Verdict:** ✅ Approve / ⚠️ Approve with comments / ❌ Request changes

---

### Changes
| File | Type | Risk |
|------|------|------|
| `src/auth/handler.go` | Modified | 🔴 High |
| `README.md` | Modified | 🟢 Low |

---

### CI Status
| Job | Status |
|-----|--------|
| test (ubuntu-latest) | ✅ Passed |
| lint | ✅ Passed |
| security-scan | ❌ Failed |

---

### Security
{List any security-relevant findings, or "No security concerns found."}

---

### Concerns
{Numbered list of specific concerns with file:line references, or "None."}

1. `src/auth/handler.go:42` — JWT secret read from env var without validation.
   Recommendation: validate non-empty at startup; fail fast.

---

### Suggestions (non-blocking)
{Optional improvements that don't block merge}

---

### Verdict
{Final decision with rationale}
```

### Step 6: Deliver
- If `PR_DELIVERY = github_comment`: post as a PR review comment via GitHub API
- If `PR_DELIVERY = telegram`: send formatted digest
- If `PR_DELIVERY = file`: write to `~/pr-reviews/{date}-PR{N}.md`

---

## Example Invocation Prompts

**Single PR review:**
```
Review PR #47 in owner/pandora-box-console. Check security, CI, and test coverage.
Post review as a GitHub comment.
```

**Nightly batch review:**
```bash
hermes cron create "0 22 * * *" \
  --workdir ~/projects/pandora-box-console \
  --prompt "Review all open PRs in this repo. Summarize CI status and security-relevant changes. Post findings to Telegram." \
  --deliver telegram \
  --profile coder
```

**Go repo:**
```
Review PR #12 in owner/go-api-service.
Apply Go-specific checks: error return ignored, goroutine leak, context propagation, interface satisfaction.
```

**TypeScript/Next.js repo:**
```
Review PR #33 in owner/nextjs-app.
Check: no direct DOM manipulation bypassing React, no useEffect missing deps, no hardcoded API URLs, no client-side secret exposure.
```

**Python repo:**
```
Review PR #8 in owner/data-pipeline.
Check: no bare except clauses, no mutable default args, no pickle.loads on untrusted data, no subprocess shell=True.
```

---

## Known Edge Cases

| Situation | Handling |
|-----------|---------|
| Diff > 500 lines | Switch to summary mode; note inability to do full review; recommend split |
| Draft PR | Note it is a draft; apply lighter-touch review unless explicitly asked |
| Dependency-only PR (lock file updates) | Focus entirely on CVE check via web lookup; skip code style |
| All CI jobs pending | Note status as pending; re-run review when CI completes if possible |
| PR has no description | Flag as concern; request description before merging |
| Merge conflict detected | Flag immediately; do not proceed with code review until resolved |
| Same file reviewed in a prior comment | Reference prior comment; avoid duplicating the same concern |

---

## Success Criteria

The review is complete only when:

- PR metadata, changed files, diff scope, and CI status were fetched or the unavailable data was called out.
- The review applied project instructions from `AGENTS.md`, `.cursorrules`, or memory when available.
- Findings include specific file and line references when the diff provides them.
- Security, tests, dependencies, docs impact, and breaking-change risk were considered.
- The final verdict is explicit and delivery happened through the configured channel.

---

## Memory Integration

After each run, optionally update MEMORY.md:
```
PR review pattern: {repo} PRs often fail {job} due to {reason}. Fix: {fix}.
```
Accumulate these patterns so future reviews can pre-check known failure modes.
