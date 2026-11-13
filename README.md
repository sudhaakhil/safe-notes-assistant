# Safe Notes Assistant

**Assignment 1, Topic 49: Build a Safe Agentic AI Application With Permissions and Execution Limits**

This is a terminal app. You ask in plain English ("Read my class notes"), an AI *proposes* an action,
and Python code decides whether that action may run. The checks are:

| Tool | Allowed files | Rule |
|---|---|---|
| `read_note` | `class.txt`, `summary.txt` | Reads only inside `demo_notes`. No approval needed (read-only). |
| `save_note` | `summary.txt` | Shows the summary and destination, then waits for `y` at `Approve save? [y/N]`. |

- **Limit:** at most **3 proposed tool calls per request**. Blocked proposals count too. A 4th proposal is stopped before it runs.
- **Audit log:** every outcome is written to `audit_log.jsonl` (timestamp, mode, tool, path, outcome, reason). Note contents, prompts and API keys are never logged.
- **Two modes:** `OFFLINE DEMO MODE` (fixed, predefined proposals; no key, no internet) and `LIVE AI MODE` (Anthropic API + LangGraph). Both modes go through the same LangGraph checks.

All notes are synthetic sample data.

---

## 1. Offline quick start (do this first)

### 1.1 Download and open the project
1. On GitHub, choose **Code > Download ZIP**, then extract the downloaded archive. You can also clone this repository.
2. In VS Code, choose **File > Open Folder...** and select the `safe-notes-assistant` folder that **directly contains `app.py` and `demo_notes`**.
   (If the Explorer shows only one folder named `safe-notes-assistant`, you opened the folder above it. See Troubleshooting.)
3. Open a terminal: **Terminal > New Terminal**. It should be PowerShell, and its path should end in `\safe-notes-assistant`.

### 1.2 Create a virtual environment and install dependencies
A virtual environment (`.venv`) is a private copy of Python just for this project.
Run these commands one at a time:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

We call `.\.venv\Scripts\python.exe` directly, so you never have to "activate" the environment or change PowerShell's execution policy.

### 1.3 Run the offline demo
```powershell
.\.venv\Scripts\python.exe app.py --mode offline
```

First demo input: type `Read my class notes` and press Enter. Expected output:

```text
=== OFFLINE DEMO MODE (predefined proposals, no API key, no network) ===
Rules: read class.txt/summary.txt, save only summary.txt after 'y', max 3 tool calls per request.
Type a request, 'audit' to view the audit log, or 'quit' to exit.

You> Read my class notes

Proposed action #1 (limit 3): read_note(path='class.txt') - user asked to read a note

===== demo_notes/class.txt =====
Review tokenization on Friday. Submit the worksheet on Friday. Bring one example of how punctuation changes token counts.
=================================
[done] Request complete.
```

Offline requests it understands (keyword-based): `Read my class notes`, `Summarize my class notes and save the summary`,
`Read my summary`, `Read the README outside the notes folder`, `Read my diary`, `Delete my class notes`,
`Read my notes again and again`. Type `audit` to see the log and `quit` to exit.
The full step-by-step script is in [docs/demo-checklist.md](docs/demo-checklist.md).

To start over at any time:
```powershell
.\.venv\Scripts\python.exe app.py --reset-demo
```

---

## 2. Live AI mode (Anthropic API)

### 2.1 Configure
```powershell
Copy-Item .env.example .env
code .env
```
Edit `.env` so it says (with your real values in place of the placeholders):
```text
ANTHROPIC_API_KEY=<your-api-key>
ANTHROPIC_MODEL=<model-name, e.g. claude-opus-5-5>
```

**Where settings come from:** `app.py` loads `.env` from the project folder (next to `app.py`).
If a variable is already set in your PowerShell session, that value wins. You can also set them only for the
current terminal instead of using `.env`:
```powershell
$env:ANTHROPIC_API_KEY = "<your-api-key>"
$env:ANTHROPIC_MODEL = "claude-opus-5-5"
```

### 2.2 Run
```powershell
.\.venv\Scripts\python.exe app.py --mode live
```
You should see `=== LIVE AI MODE (Anthropic API, model: ...) ===`. Try `Read my class notes`, then
`Summarize my class notes and save the summary`. In live mode Claude reads `class.txt`, writes the summary
itself, and proposes saving it. The summary appears on screen before `Approve save? [y/N]`.

Each request has a 30-second timeout with up to 2 retries. Timeouts, a bad key, a wrong model name, rate limits,
network errors and invalid model output each print a clear `[failed] ...` message and are logged.

### 2.3 Keep your key private
- Never show `.env` on screen. Close that tab before taking screenshots, and don't run `type .env`.
- `.env` is listed in `.gitignore` and `.dockerignore`. If you make your own ZIP, delete `.env` and `.venv` first (see section 5).
- The app never prints or logs the key.

---

## 3. Run the tests
```powershell
.\.venv\Scripts\python.exe -m pytest -v
```
The tests use temporary copies of the notes and a simulated model, so they need no API key and never change `demo_notes/class.txt`.
(One test checks symbolic links. On Windows it is **skipped** unless Developer Mode is on, because Windows only lets normal users create links in that mode.)

---

## 4. Isolated Docker demo (optional)
You need Docker Desktop installed and running.
```powershell
docker build -t safe-notes-assistant .
docker run --rm -it --network none --name sna-demo safe-notes-assistant
```
- `--rm` deletes the container when you exit. `--network none` means no internet access. There is no `-v`, so no folder from your PC is mounted.
- The sample notes are copied into the image. While the container runs, the summary is in `/app/demo_notes/summary.txt` and the log is in `/app/audit_log.jsonl`, **inside the container only**. Both disappear when you type `quit`.
- To see the audit records before exiting, type `audit` at the `You>` prompt. Or, from a second PowerShell window:
  ```powershell
  docker exec sna-demo cat /app/audit_log.jsonl
  ```

What each layer protects: the **Python checks** decide which tool, file and write are allowed, even if the AI asks for something else.
The **container** limits the damage if those checks had a bug: the app can only see its own copy of the files and has no network.
Live mode in Docker would need network access and a key, so the Docker demo is offline only.

---

## 5. Make your own ZIP (if you change files)
Run this from the folder **above** `safe-notes-assistant`. It copies the project without `.venv`, `.env`, logs or summaries, then zips the copy:
```powershell
$src = ".\safe-notes-assistant"; $tmp = "$env:TEMP\sna-zip\safe-notes-assistant"
Remove-Item "$env:TEMP\sna-zip" -Recurse -Force -ErrorAction SilentlyContinue
robocopy $src $tmp /E /XD .venv __pycache__ .pytest_cache /XF .env audit_log.jsonl summary.txt *.zip | Out-Null
Compress-Archive -Path $tmp -DestinationPath .\safe-notes-assistant.zip -Force
```

---

## 6. Troubleshooting

**`app.py` became a folder.** If the Explorer shows a folder icon named `app.py`: delete it (right-click > Delete), make sure the real
`app.py` file from the ZIP is in the project folder, and check with `Get-Item app.py` that `Mode` begins with `-a` (a file), not `d` (a folder).

**VS Code opened one folder too high.** The Explorer shows `safe-notes-assistant > safe-notes-assistant > app.py`, or the terminal says
`can't open file ... app.py`. Fix: **File > Open Folder...**, then select the *inner* `safe-notes-assistant`. Or run `cd .\safe-notes-assistant` in the terminal.
Check with `Get-ChildItem`: you should see `app.py` and `demo_notes`.

**`FileNotFoundError` for `demo_notes/class.txt`.** The app finds notes next to `app.py` (not next to your terminal), so this means the file
really is missing. Check with `Test-Path .\demo_notes\class.txt`. If it prints `False`, extract the ZIP again (don't copy only `app.py`).
Make sure the file is named `class.txt` and not `class.txt.txt` (in File Explorer, turn on **View > Show > File name extensions**).

**`demo_notes/summary.txt does not exist yet`.** This is expected before your first approved save. Run the summarize request and type `y`.

**Missing API settings.** `[failed] Missing setting(s): ANTHROPIC_API_KEY ...` means `.env` is missing, is in the wrong folder, or is still
named `.env.example`. Run `Test-Path .\.env`. It must print `True` and the file must sit next to `app.py`.
`API key was rejected` means the key is wrong. `model not found` means `ANTHROPIC_MODEL` is wrong.

**Dependency installation errors.**
- `py` is not recognized: install Python 3.12 from python.org and tick **Add python.exe to PATH**, or use `python -m venv .venv`.
- `No module named langgraph` (or `anthropic`): you ran plain `python` instead of `.\.venv\Scripts\python.exe`. Rerun the install command from 1.2.
- Network or SSL errors: check your internet or proxy and retry. `pip install` needs internet, but the offline demo itself does not.
- If something is half-installed, delete `.venv` and start 1.2 again: `Remove-Item .venv -Recurse -Force`.

---

## 7. What each file does

| File | Purpose |
|---|---|
| `app.py` | The whole app: tool rules, path checks, offline and live planners, the LangGraph workflow, the audit log, and the command line. |
| `requirements.txt` | The Python packages to install, with compatible version ranges. |
| `.env.example` | Template for your private `.env` settings (API key and model name). |
| `.gitignore` | Keeps `.env`, `.venv`, logs and generated summaries out of git. |
| `Dockerfile` | Builds a small isolated image that runs the offline demo as a non-root user. |
| `.dockerignore` | Keeps `.env`, `.venv` and runtime files out of the Docker image. |
| `demo_notes/class.txt` | The synthetic class note the assistant may read. |
| `tests/test_assistant.py` | Automated tests for reading, saving, declining, blocking, limits, the audit log and simulated live mode. |
| `docs/demo-checklist.md` | Exact demo steps, expected outputs and when to take each screenshot. |
| `docs/workflow.md` | Mermaid workflow diagram and an explanation of each step. |
| `docs/medium-article-outline.md` | Article outline, results table, 60-second demo script and viva Q&A. |

**Versions tested:** Python 3.12.10 on Windows 11 with anthropic 2.8.0, langgraph 1.2.21, pydantic 2.14.3, python-dotenv 1.2.4, pytest 9.2.0.

## Assignment articles

- [Article 1 — Risks of Autonomous AI Systems](https://medium.com/@sudhaakhil67/risks-of-autonomous-ai-systems-fd59b3aa543f)
- [Article 2 — Building a Safe Notes Assistant](https://medium.com/@sudhaakhil67/the-ai-proposes-python-decides-building-a-safe-notes-assistant-with-permissions-and-limits-b6db29b14c8d)
