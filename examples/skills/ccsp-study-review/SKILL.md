# Skill: Security Certification Study Review (CCSP / CPSA / CRT / CISSP)

## Metadata
- **Version:** 1.0.0
- **Compatible with:** Hermes Agent 0.x+
- **Standard:** agentskills.io/v1

## Triggers
Invoke this skill when the user says any of:
- "study review"
- "CCSP review"
- "exam prep"
- "wrong answer analysis"
- "weekly study summary"
- "what did I get wrong this week"
- "drill list"

---

## Tools Required
| Tool | Purpose |
|------|---------|
| `file` | Read study notes, wrong-answer logs, session notes from local paths |
| `memory` | Read active certifications, weak domains, study schedule from MEMORY.md |
| `web` | Look up official domain definitions or clarify concepts if needed |

---

## Customization Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `STUDY_CERT` | `CCSP` | Active certification: CCSP, CPSA, CRT, CISSP, CISM, etc. |
| `STUDY_NOTES_PATH` | `~/study/` | Path to session notes and wrong-answer logs |
| `STUDY_OUTPUT_PATH` | `~/study/weekly/` | Where to write weekly review Markdown |
| `STUDY_MAX_DRILL_ITEMS` | `5` | Max items in next-week drill list |
| `STUDY_LANGUAGE` | `en` | Output language (en or zh-TW) |
| `STUDY_INCLUDE_CITATIONS` | `true` | Reference official domain descriptions in output |

---

## CCSP Domain Reference

| Domain | Code | Topics |
|--------|------|--------|
| Cloud Concepts, Architecture & Design | D1 | Cloud reference architectures, design principles, DevSecOps, shared responsibility |
| Cloud Data Security | D2 | Data lifecycle, classification, DRM, DLP, encryption at rest/transit |
| Cloud Platform & Infrastructure Security | D3 | Physical/virtual infrastructure, network security, BC/DR in cloud |
| Cloud Application Security | D4 | SDLC, SAST/DAST, identity/access in cloud apps, API security |
| Cloud Security Operations | D5 | Monitoring, incident response, digital forensics in cloud, log management |
| Legal, Risk & Compliance | D6 | Jurisdictional issues, eDiscovery, audit, contracts, privacy frameworks |

---

## CPSA Domain Reference (for customization)

| Domain | Topics |
|--------|--------|
| Network Security Testing | Reconnaissance, scanning, enumeration, exploitation |
| Web Application Security | OWASP Top 10, authentication flaws, injection, CSRF |
| Infrastructure Testing | Active Directory, privilege escalation, lateral movement |
| Reporting | Finding severity, remediation guidance, executive summary |

---

## CRT Domain Reference (for customization)

| Domain | Topics |
|--------|--------|
| Core Concepts | Red team methodology, OPSEC, threat modelling |
| Initial Access | Phishing, external exposure exploitation, credential attacks |
| Post-Exploitation | Enumeration, persistence, privilege escalation, lateral movement |
| Evasion | AV/EDR bypass concepts, LOLBins, detection avoidance |

---

## Step-by-Step Procedure

### Step 1: Load study context
```
Read MEMORY.md for:
- Active certification and target exam date
- Known weak domains (e.g., "D4 and D6 are weakest")
- Study schedule (sessions per week, topics covered)
- Running list of repeated misconceptions

Read from STUDY_NOTES_PATH:
- Session notes files ({date}-session.md or similar)
- Wrong-answer log (wrong-answers.md or CSV)
- Any practice exam results
```

### Step 2: Parse wrong-answer data

From wrong-answer log, extract:
```
For each wrong answer:
  - Domain (D1–D6 for CCSP, or equivalent)
  - Topic/subtopic
  - Question summary or ID
  - Why it was wrong (if noted)
  - Number of times this topic appeared
```

Group by domain and subtopic. Count frequency.

### Step 3: Identify domain coverage gaps

```
For each domain:
  count_studied = number of questions or session time in this domain
  count_wrong = wrong answers in this domain
  error_rate = count_wrong / count_studied

Sort domains by error_rate descending.
Flag domains with error_rate > 0.3 as HIGH PRIORITY.
Flag domains with count_studied == 0 as NOT COVERED.
```

### Step 4: Classify misconception types

For each repeated wrong topic, classify:

| Type | Description | Example |
|------|-------------|---------|
| **Conceptual** | Fundamental misunderstanding of a term or model | Confusing FIPS 140-2 levels |
| **Distinction** | Confusing two similar concepts | CASB vs DLP; audit vs assessment |
| **Exam trap** | Correct concept but wrong answer due to question framing | "Which is BEST?" / "MOST likely" / "FIRST" |
| **Recall gap** | Knew the topic but forgot a specific fact | Max retention period under GDPR |
| **Scope error** | Knowing the concept but applying wrong domain | Applying D3 network controls to a D6 compliance question |

### Step 5: Generate drill list

Select `STUDY_MAX_DRILL_ITEMS` topics for next week, prioritized by:
1. High error rate AND high exam weight
2. Repeated misconceptions (appeared wrong 2+ times)
3. Domains not yet covered
4. Exam trap patterns (framing-based errors)

For each drill item, include a targeted practice prompt:
```
Topic: {topic}
Focus: {specific subtopic or question type}
Suggested resources: {official guide chapter, study deck, or web search}
Practice prompt: "Explain the difference between X and Y in the context of {domain}."
```

### Step 6: Compose output

**Output format (Markdown):**

```markdown
# {STUDY_CERT} Weekly Study Review — {date}

## Domain Coverage This Week
| Domain | Questions Studied | Wrong | Error Rate | Priority |
|--------|-----------------|-------|-----------|---------|
| D1 — Cloud Architecture | 15 | 2 | 13% | 🟢 OK |
| D4 — Application Security | 12 | 6 | 50% | 🔴 HIGH |
| D6 — Legal & Compliance | 8 | 4 | 50% | 🔴 HIGH |
| D3 — Infrastructure | 10 | 1 | 10% | 🟢 OK |
| D2 — Data Security | 0 | — | — | ⬜ NOT COVERED |
| D5 — Security Operations | 5 | 1 | 20% | 🟡 WATCH |

## Repeated Misconceptions
1. **{topic}** — confused {A} with {B}. Key distinction: {correct distinction}.
2. **{topic}** — missed that {specific fact}. Remember: {mnemonic or rule}.

## Exam Trap Patterns Observed
1. Questions asking "Which is MOST appropriate?" in D6 — look for the option that protects data subject rights first.
2. "FIRST step" questions in incident response — answer is always contain/isolate before analyze.

## Next Week Drill List
- [ ] D4: API security testing in SDLC — focus on OWASP API Security Top 10
- [ ] D6: eDiscovery process steps and legal hold obligations
- [ ] D2: Distinguish between DRM, DLP, and tokenization use cases
- [ ] D4: OAuth 2.0 vs SAML vs OIDC in cloud context
- [ ] D6: GDPR data subject rights — enumerate all 8 rights

## Notes
{Any additional session notes or observations}

---
Generated by Hermes Agent study-review skill · {timestamp}
```

### Step 7: Save output

Write to `{STUDY_OUTPUT_PATH}/review-{date}.md`

Optionally update MEMORY.md:
```
CCSP weak domains: D4 (50% error), D6 (50% error), D2 (not covered). Updated {date}.
```

---

## Example Invocation Prompts

**Interactive:**
```
Run the CCSP study review skill.
Read my notes from ~/study/. Identify weak domains, misconceptions, and exam traps.
Generate a drill list for next week. Save to ~/study/weekly/review-today.md.
```

**Weekly cron:**
```bash
hermes cron create "0 20 * * 0" \
  --prompt "Run ccsp-study-review skill. Notes at ~/study/. Save output to ~/study/weekly/." \
  --deliver file:~/study/weekly/review-$(date +%F).md \
  --profile study
```

**Targeted domain review:**
```
Run study review skill, but focus only on D6 (Legal, Risk & Compliance).
List every question I got wrong in D6 this week and explain the correct reasoning.
```

**Other certification (CPSA):**
```
Run study review skill for CPSA exam.
Focus on web application security domain. Identify patterns in my wrong answers.
```

---

## Known Edge Cases

| Situation | Handling |
|-----------|---------|
| No wrong-answer log found | Note the absence; ask user to provide path or create a template log file |
| Domain coverage is 100% correct this week | Celebrate briefly; focus drill list on hardest exam-weight topics |
| Notes files are empty or missing dates | Use available content; note missing sessions |
| All wrong answers in one domain | Flag for intensive review; suggest scheduling a dedicated session |
| User asking about a cert not in reference | Search `web` for official domain breakdown; adapt the output structure |

---

## Wrong-Answer Log Template

Create this file at `~/study/wrong-answers.md` and update it during study sessions:

```markdown
# Wrong Answers Log

| Date | Cert | Domain | Topic | Question Summary | Why Wrong |
|------|------|--------|-------|-----------------|-----------|
| 2026-04-20 | CCSP | D6 | eDiscovery | Steps in legal hold process | Confused preservation with collection |
| 2026-04-21 | CCSP | D4 | API Security | OAuth token storage | Chose session cookie; correct is HttpOnly secure cookie |
```
