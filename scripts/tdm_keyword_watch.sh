#!/usr/bin/env bash
# TDM keyword watch: lightweight poll, no LLM per check.
# Reads keywords from ~/workspace/custom-skills/tdm/keywords.json (managed in the TDM space),
# fetches the latest TDM news list, and wakes an agent only when a NEW item matches a keyword.
set -euo pipefail
source "$HATCH_HOOK_RUNTIME"

KW_FILE="$HOME/workspace/custom-skills/tdm/keywords.json"
STATE_DIR="$HOME/hooks/state/tdm_keyword_watch"
SEEN_FILE="$STATE_DIR/seen_ids.txt"
RESULT_FILE="$STATE_DIR/last_result.json"
mkdir -p "$STATE_DIR"

if [ ! -f "$KW_FILE" ]; then
  silent "no keywords file yet"
  exit 0
fi

DRY="${HATCH_HOOK_DRY_RUN:-0}"
RESULT="$(python3 - "$KW_FILE" "$SEEN_FILE" "$RESULT_FILE" "$DRY" <<'PY'
import json, sys
sys.path.insert(0, "/home/hatch/workspace/custom-skills/tdm/scripts")
kw_file, seen_file, result_file, dry = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"

try:
    with open(kw_file, encoding="utf-8") as f:
        keywords = [str(k).strip() for k in json.load(f) if str(k).strip()]
except Exception:
    keywords = []
if not keywords:
    print(json.dumps({"seed": False, "hits": [], "reason": "no keywords configured"}, ensure_ascii=False))
    sys.exit(0)

from tdm_core import query_news_list
try:
    r = query_news_list(page=1, size=40)
    items = r.get("items", [])
except Exception as e:
    print(json.dumps({"seed": False, "hits": [], "reason": f"fetch failed: {e}"}, ensure_ascii=False))
    sys.exit(0)

import os
seen = set()
seed = False
if os.path.exists(seen_file):
    with open(seen_file, encoding="utf-8") as f:
        seen = {line.strip() for line in f if line.strip()}
else:
    seed = True

hits = []
if not seed:
    for it in items:
        nid = str(it.get("id", ""))
        title = it.get("title", "") or ""
        if not nid or nid in seen:
            continue
        matched = [kw for kw in keywords if kw.lower() in title.lower()]
        if matched:
            hits.append({
                "id": nid,
                "title": title,
                "date": it.get("date", ""),
                "keyword": matched[0],
                "url": f"https://www.tdm.com.mo/zh-hant/news-detail/{nid}",
            })

if not dry:
    with open(seen_file, "w", encoding="utf-8") as f:
        for it in items:
            nid = str(it.get("id", ""))
            if nid:
                f.write(nid + "\n")
        for h in hits:
            f.write(h["id"] + "\n")

out = {"seed": seed, "hits": hits, "reason": ""}
with open(result_file, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False)
print(json.dumps(out, ensure_ascii=False))
PY
)"

SEED="$(echo "$RESULT" | jq -r '.seed')"
HITS="$(echo "$RESULT" | jq -r '.hits | length')"
REASON="$(echo "$RESULT" | jq -r '.reason // ""')"

if [ "$SEED" = "true" ]; then
  silent "seeded seen list, no alert on old news"
  exit 0
fi
if [ -n "$REASON" ] && [ "$REASON" != "" ] && [ "$REASON" != "null" ]; then
  log "observation" "{\"reason\": $(echo "$REASON" | jq -Rs .)}"
  silent "no keywords or fetch failed: $REASON"
  exit 0
fi
if [ "$HITS" -gt 0 ]; then
  log "observation" "$RESULT"
  wake "new TDM news matched monitored keywords" "$RESULT"
  exit 0
fi
silent "no new keyword matches"
exit 0
