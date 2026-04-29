# Skill: Daily Briefing

## Metadata
- **Version:** 1.0.0
- **Compatible with:** Hermes Agent 0.x+
- **Standard:** agentskills.io/v1

## Triggers
Invoke this skill when the user says any of:
- "daily briefing"
- "morning update"
- "news summary"
- "what happened today"
- "morning digest"
- "catch me up"

Also triggered automatically by cron when scheduled.

---

## Tools Required
| Tool | Purpose |
|------|---------|
| `web` | Search news sources and fetch article content |
| `memory` | Read topic preferences and delivery settings from MEMORY.md |
| `messaging` | Deliver final briefing to configured platform |
| `file` | Optionally save output to local Markdown file |

---

## Customization Variables

Edit these in MEMORY.md or pass inline at invocation time:

| Variable | Default | Description |
|----------|---------|-------------|
| `BRIEFING_TOPICS` | See default list below | Comma-separated list of search topics |
| `BRIEFING_LANGUAGE` | `Traditional Chinese` | Output language |
| `BRIEFING_MAX_ITEMS` | `3` | Max news items per topic |
| `BRIEFING_SUMMARY_LENGTH` | `2 sentences` | Length per item summary |
| `BRIEFING_REQUIRE_LINKS` | `true` | Always include source URL |
| `BRIEFING_DELIVERY` | `telegram` | Delivery target: `telegram`, `discord`, `file`, `slack` |
| `BRIEFING_EXCLUDE_KEYWORDS` | `funding,valuation,IPO` | Topics to suppress unless engineering-relevant |
| `BRIEFING_PRIORITY_SOURCES` | `github.com,arxiv.org` | Sources to rank higher |

### Default Topic List
```
1. AI agent frameworks (new releases, GitHub activity, research papers)
2. Open-source LLM releases (models, benchmarks, fine-tunes)
3. Cloud security and zero trust news
4. UK scholarship and postgraduate funding deadlines
```

---

## Step-by-Step Procedure

### Step 1: Load preferences
```
Read MEMORY.md and USER.md for:
- Preferred topics (BRIEFING_TOPICS)
- Language preference
- Excluded keywords
- Priority sources
- Delivery target
```

### Step 2: Search each topic
For each topic in the topics list:
```
web_search(query="{topic}", time_filter="past 24 hours", max_results=10)
```
- Deduplicate results by URL and by title similarity (>80% overlap = duplicate)
- Discard results matching BRIEFING_EXCLUDE_KEYWORDS unless the article is from a priority source

### Step 3: Filter by relevance
Score each result on a 1–5 scale:
- +2: from a priority source (GitHub, arXiv, vendor engineering blog)
- +2: contains a release, benchmark, or technical detail
- +1: less than 6 hours old
- -2: business/funding/valuation framing with no engineering content
- -1: paywalled (detected via paywall indicators in URL or meta tags)

Keep the top `BRIEFING_MAX_ITEMS` results per topic.

### Step 4: Summarize each item
For each selected result:
```
Fetch article content or use search snippet.
Summarize in BRIEFING_LANGUAGE.
Format: [Title](URL) — {BRIEFING_SUMMARY_LENGTH summary}
```

If the article is paywalled, use only the title, source, and any available snippet. Do not fabricate content.

### Step 5: Assemble and deliver

**Output format template:**
```
📋 每日簡報 — {date}

🤖 AI Agent 框架
• [Article Title](https://source.url) — 摘要句子一。摘要句子二。
• [Article Title](https://source.url) — 摘要句子一。摘要句子二。

🔓 開源 LLM
• ...

☁️ 雲端安全
• ...

🎓 獎學金資訊
• ...

---
由 Hermes Agent 自動生成 · {timestamp}
```

Deliver to BRIEFING_DELIVERY target.
Optionally write to `~/briefings/{date}.md` if file output is configured.

---

## Example Invocation Prompts

**Interactive:**
```
Run the daily briefing skill. Topics: AI agents, cloud security, UK scholarships.
Summarize in Traditional Chinese, max 3 items per topic, include source links.
Send to Telegram.
```

**Cron (scheduled):**
```bash
hermes cron create "0 8 * * *" \
  --prompt "Run daily-briefing skill." \
  --deliver telegram \
  --profile personal
```

**One-shot with overrides:**
```
Run daily briefing, but focus only on: open-source LLM releases today.
English output. Max 5 items. Save to ~/briefings/today.md.
```

---

## Known Edge Cases

| Situation | Handling |
|-----------|---------|
| Paywalled article | Use title + snippet only; mark with `[paywall]` tag |
| Duplicate stories across sources | Keep highest-scoring source; deduplicate by title similarity |
| No results for a topic | Output: `{Topic}: 今日無最新消息。` |
| Search API rate limit hit | Skip remaining topics; note which topics were skipped |
| Delivery platform unavailable | Save to `~/briefings/{date}.md` as fallback |
| Briefing is empty (all filtered out) | Still deliver with a note: `今日所有結果已被過濾，請調整關鍵字設定。` |

---

## Success Criteria

The run is complete only when:

- Each configured topic was searched or explicitly marked as skipped with a reason.
- Selected items include source links and do not exceed `BRIEFING_MAX_ITEMS` per topic.
- Summaries follow `BRIEFING_LANGUAGE` and `BRIEFING_SUMMARY_LENGTH`.
- Duplicate or low-relevance results were filtered before delivery.
- The briefing was delivered to `BRIEFING_DELIVERY`, or a local fallback path was reported.

---

## Memory Integration

After a successful run, update MEMORY.md with:
```
Last briefing: {date} — {N} items across {M} topics. Delivery: {platform}.
```

If the user provides feedback ("skip funding news", "add arXiv to AI section"), update the preference in MEMORY.md immediately.
