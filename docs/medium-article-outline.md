# Medium Article Outline

## Title
**"The AI Proposes, Python Decides: Building a Safe Notes Assistant with Permissions and Limits"**

## Introduction (2-3 short paragraphs)
AI agents can do more than chat: they can call tools that read and write files. That makes them useful, and it also makes
them risky. For Assignment #49 I built a small terminal assistant that reads a class note and saves a summary. It uses
Claude through the Anthropic API and LangGraph, but the model never gets the final say. Every action passes through Python
permission checks, a human approval step for writes, a three-action limit, and an audit log.

## 1. The problem
An AI assistant that can read and write files needs clear boundaries. It could open a file outside its assigned folder, overwrite a note without permission, or keep retrying a blocked action. I built Safe Notes Assistant to demonstrate three controls: file permissions, human approval before saving, and a three-action limit per request.

## 2. The design
Safe Notes Assistant has two tools: one reads `class.txt` or `summary.txt`, and the other saves only `summary.txt`. LangGraph runs the workflow, and Python checks each proposed action against the allowed files and the three-action limit. Before saving, the assistant shows the proposed summary and asks for approval. The audit log records the outcome of each action.

Offline mode uses predefined proposals, while live mode uses Claude to propose actions. Both modes go through the same Python checks. The screenshots in this article show the offline demo.

![Allowed files and three-action limit](../screenshots/07_permission_settings.png)

## 3. Implementation
LangGraph runs the workflow for each request. The planner proposes a tool and its arguments. Python validates the proposal and checks the filename against the tool’s allowlist. Each proposed tool call counts toward the limit, including blocked attempts. If a fourth tool call is proposed, the workflow stops before it runs.

For a save request, the app shows the proposed summary and its destination, `demo_notes/summary.txt`. It writes the file only after the user enters `y` at the approval prompt. The audit log records the tool, timestamp, outcome, and reason.

## 4. Test results
I ran the offline demo to check note reading, approved and declined saves, blocked file access, and the three-action limit. The audit log recorded each outcome. The table and screenshots below show what happened during the demo.
### Offline Demo Screenshots

![Successful note read](../screenshots/01_successful_read.png)

![Approved summary save](../screenshots/02_approved_save.png)

![Declined summary save](../screenshots/03_declined_save.png)

![Blocked access outside the notes folder](../screenshots/04_blocked_file_access.png)

![Three-action limit](../screenshots/05_action_limit.png)

![Audit log](../screenshots/06_audit_log.png)

## 5. Limitations
The offline demo uses predefined actions and a fixed sample summary. It shows how the app checks permissions, asks for approval, and stops at the action limit. Approval gives the user a chance to review the proposed summary, but the user still needs to check it for accuracy. A successful run with the live Anthropic API and a run inside Docker are pending verification.

## 6. Lessons learned
This project taught me how to give an AI assistant limited access to files. Python checks each proposed action, and the approval prompt gives the user a chance to review a summary before saving it. Counting blocked attempts toward the three-action limit prevents repeated retries. The audit log helped me check which actions ran and why others were blocked.

## 60-second class demo script
> "This is my Safe Notes Assistant. The AI can only *suggest* actions. Python decides if they run.
> I'm in offline demo mode, so it uses fixed proposals and needs no internet.
> First, I'll say 'Read my class notes'. Reading class.txt is allowed, so it shows the note.
> Now 'Summarize my class notes and save the summary'. Before saving, it shows me the exact summary and where it will go.
> I type y, and it's saved. If I ask again and type n, nothing changes. It even warns me that saving would replace the file.
> Next, I'll try to read a file outside the notes folder. It's blocked, even though the file exists.
> Now 'Read my notes again and again'. It runs three times, and the fourth attempt is stopped. That's the execution limit.
> Finally, 'audit' shows every decision with a timestamp, the tool, the outcome and the reason, but never the note text.
> The same checks run in live mode with Claude, and the Docker version adds an isolated box with no network."

---

## Likely viva questions

1. **Why does Python check permissions instead of the AI?**
   The model can make mistakes or be tricked by text in a note. Python rules are fixed code that always run, so the model can only propose. It can never decide.

2. **What counts toward the three-action limit?**
   Every proposed tool call in one request: successful, blocked or declined. Only `finish` doesn't count. The 4th proposal is blocked before it runs, and the counter resets for each new request.

3. **What does the audit log record?**
   One JSON line per event: timestamp, mode, tool, path, outcome (success, approved, declined, blocked, failed, limit_reached) and reason. It never records note contents, prompts or API keys.

4. **How do you stop path tricks like `../` or links?**
   The name must be a plain file name with no slashes, colons or `..`, and it must be on the tool's allowlist. Then `Path.resolve()` follows any link, and the real path must still be inside `demo_notes`.

5. **What does Docker add if Python already checks everything?**
   Defense in depth. If a check had a bug, the container still has no network, no access to my PC's folders, runs as a non-root user, and is deleted on exit. It can't stop a human from approving a bad summary, though.
