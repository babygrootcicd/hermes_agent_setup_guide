# Task: <Feature Title>

## Goal
Implement `<feature>` in `<scope>` with minimal blast radius and verifiable behavior changes.

## Ownership & Constraints
- Editable paths: `<list allowed paths>`
- Non-editable paths: `<list restricted paths>`
- Runtime constraints: `<sandbox/network/tool limits>`
- Style constraints: `<language/framework conventions>`

## Sub-Tasks
- [ ] Read relevant code paths and existing patterns
- [ ] Implement behavior changes
- [ ] Add/adjust tests for changed behavior
- [ ] Run verification commands
- [ ] Produce final implementation report

## Context
Generated with:

```bash
./scripts/common/gather_context.sh <path1> <path2> ...
```

Paste output below this line:

---

## Output Contract (Required)
Final response must include all sections below in order.

1. `Status`
   - One of: `complete` | `partial` | `blocked`
   - Include one-sentence rationale.

2. `Changed Files`
   - Bullet list of touched files only.
   - Per file include a one-line summary of what changed.

3. `Implementation Details`
   - Brief explanation of the functional change.
   - Note any assumptions made.

4. `Verification Done`
   - List exact commands run.
   - For each command include `pass` or `fail`.
   - If not run, state why.

5. `Risks`
   - List remaining risks, edge cases, or follow-ups.
   - Use `none` if no known risks remain.

## Acceptance Criteria
- Behavior matches the requested feature scope.
- Output Contract is fully satisfied.
- Verification commands are included with outcomes.
- No edits outside declared ownership.

## Final Response Skeleton
Use this exact section order in the final delivery:

```md
## Status
<complete|partial|blocked> — <one-sentence rationale>

## Changed Files
- <path> — <change summary>

## Implementation Details
<brief implementation notes + assumptions>

## Verification Done
- `<command>` — pass|fail

## Risks
<risk list or `none`>
```
