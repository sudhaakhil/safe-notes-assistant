# Demo Checklist (offline, reproducible)

Run everything from the project folder (the one containing `app.py`) in the VS Code PowerShell terminal.
Every case below runs in **OFFLINE DEMO MODE**, so the proposals are the same each time.
📸 marks when to take a screenshot. Make sure `.env` is **not** visible in any screenshot.

## 0. Prepare

```powershell
.\.venv\Scripts\python.exe app.py --reset-demo
```
Expected: `Demo reset: removed demo_notes/summary.txt and audit_log.jsonl.`

📸 **Screenshot P1: permission settings.** Open `app.py` and capture the settings block near the top:
```python
ALLOWED_FILES = {
    "read_note": {"class.txt", "summary.txt"},
    "save_note": {"summary.txt"},
}
MAX_TOOL_CALLS = 3          # per user request, blocked proposals included
```
📸 **Screenshot P2: path check.** Capture the `check_action` function (plain file name only, allowlist, `resolve()` must stay in `demo_notes`).

## Start the app

```powershell
.\.venv\Scripts\python.exe app.py --mode offline
```
Expected first lines:
```text
=== OFFLINE DEMO MODE (predefined proposals, no API key, no network) ===
Rules: read class.txt/summary.txt, save only summary.txt after 'y', max 3 tool calls per request.
```
Type each request below at the `You>` prompt, in this order.

## Case 1: Successful read
**Type:** `Read my class notes`
```text
Proposed action #1 (limit 3): read_note(path='class.txt') - user asked to read a note

===== demo_notes/class.txt =====
Review tokenization on Friday. Submit the worksheet on Friday. Bring one example of how punctuation changes token counts.
=================================
[done] Request complete.
```
📸 **Screenshot 1: successful read** (include the OFFLINE DEMO MODE banner).

## Case 2: Approved save
**Type:** `Summarize my class notes and save the summary`. **At the prompt, type:** `y`
```text
Proposed action #1 (limit 3): read_note(path='class.txt') - read the source note
===== demo_notes/class.txt =====
Review tokenization on Friday. ...
=================================

Proposed action #2 (limit 3): save_note(path='summary.txt') - save the short summary

----- Proposed summary -----
Summary: On Friday, review tokenization and submit the worksheet. Bring one example of punctuation changing token counts.
----------------------------
Destination: demo_notes/summary.txt
Approve save? [y/N] y
[saved] demo_notes/summary.txt
[done] Request complete.
```
📸 **Screenshot 2: approved save** (summary, destination, `y`, `[saved]`). Optionally also open `demo_notes/summary.txt` in VS Code.

## Case 3: Declined save (existing summary stays unchanged)
**Type:** `Summarize my class notes and save the summary`. **At the prompt, type:** `n` (or just press Enter)
```text
Destination: demo_notes/summary.txt
NOTE: demo_notes/summary.txt already exists. Approving will REPLACE it.
Approve save? [y/N] n
[declined] Nothing was saved.
```
📸 **Screenshot 3: declined save** with the REPLACE warning.
Then **type:** `Read my summary`. The same summary text from Case 2 is printed, which proves the file was not changed.

## Case 4: Blocked access outside `demo_notes`
**Type:** `Read the README outside the notes folder`
```text
Proposed action #1 (limit 3): read_note(path='../README.md') - read a file outside demo_notes
[blocked] path must be a plain file name inside demo_notes
[done] Request complete.
```
📸 **Screenshot 4: blocked action.** `README.md` is a real, harmless file one folder up, and it is still blocked.

Optional extra blocks:
- `Read my diary` → `[blocked] 'diary.txt' is not an allowed file for read_note`
- `Delete my class notes` → `[blocked] unknown tool 'delete_note'`

## Case 5: Three-action limit
**Type:** `Read my notes again and again`
```text
Proposed action #1 (limit 3): read_note(path='class.txt') - read pass 1
... (note printed)
Proposed action #2 (limit 3): read_note(path='class.txt') - read pass 2
... (note printed)
Proposed action #3 (limit 3): read_note(path='class.txt') - read pass 3
... (note printed)
Proposed action #4 (limit 3): read_note(path='class.txt') - read pass 4
[blocked] limit of 3 tool calls per request reached - this request is stopped.
```
📸 **Screenshot 5: execution limit.** The 4th proposal is blocked before it runs.

## Case 6: Audit records
**Type:** `audit`
```text
--- audit_log.jsonl ---
{"timestamp": "...", "mode": "offline", "tool": "read_note", "path": "class.txt", "outcome": "success", "reason": "allowed read-only file"}
{"timestamp": "...", "mode": "offline", "tool": "read_note", "path": "class.txt", "outcome": "success", ...}
{"timestamp": "...", "mode": "offline", "tool": "save_note", "path": "summary.txt", "outcome": "approved", "reason": "user typed y"}
{"timestamp": "...", "mode": "offline", "tool": "read_note", "path": "class.txt", "outcome": "success", ...}
{"timestamp": "...", "mode": "offline", "tool": "save_note", "path": "summary.txt", "outcome": "declined", "reason": "user did not type y"}
{"timestamp": "...", "mode": "offline", "tool": "read_note", "path": "summary.txt", "outcome": "success", ...}
{"timestamp": "...", "mode": "offline", "tool": "read_note", "path": "../README.md", "outcome": "blocked", "reason": "path must be a plain file name inside demo_notes"}
... three "success" lines ...
{"timestamp": "...", "mode": "offline", "tool": "read_note", "path": "class.txt", "outcome": "limit_reached", "reason": "limit of 3 tool calls per request reached"}
```
(If you ran the optional extra blocks, you will see extra `blocked` lines.)
📸 **Screenshot 6: audit records.** Point out that no note text appears in the log.

Type `quit` to exit.

## Case 7: Automated tests
```powershell
.\.venv\Scripts\python.exe -m pytest -v
```
Expected ending: `32 passed, 1 skipped` (the symlink test is skipped on Windows without Developer Mode; it passes where links are allowed, e.g. Linux or Docker).
📸 **Screenshot 7: test results.**

## Case 8 (optional): Docker isolation
```powershell
docker build -t safe-notes-assistant .
docker run --rm -it --network none --name sna-demo safe-notes-assistant
```
Repeat Cases 2, 4 and 6 inside the container.
📸 **Screenshot 8:** the `docker run` command line (showing `--rm --network none` and no `-v`) and the app's output.

## Case 9 (optional): Live AI mode
```powershell
.\.venv\Scripts\python.exe app.py --mode live
```
Try `Read my class notes`, then `Summarize my class notes and save the summary`. The AI writes its own summary, so the wording will differ from offline mode.
📸 **Screenshot 9:** the LIVE AI MODE banner and an approval prompt. Don't show `.env`.
