# Banh Mi Ops Live Dashboard

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops
**Date:** 2026-03-29

---

## Overview

The Banh Mi Ops Live Dashboard is a self-contained HTML file that visualizes the current state of a running operation. It requires no server, no build step, and no dependencies. Open it in a browser and it reads state data directly from the filesystem.

---

## How to Use

```bash
open scripts/dashboard.html
```

On Linux, use `xdg-open` instead:

```bash
xdg-open scripts/dashboard.html
```

The dashboard will open in your default browser and begin displaying operation state immediately. If no operation is running, it displays sample data in demo mode.

---

## State File

The dashboard reads its data from:

```
.claude/banhmi/operations/current/state.json
```

This file is written and updated by the Coordinator throughout the operation lifecycle. Every significant event (task dispatch, task completion, analyst finding, revision cycle) triggers a state file update.

---

## Auto-Refresh

The dashboard polls the state file every **2 seconds**. No manual refresh is needed. When the state file changes, the display updates automatically.

---

## Demo Mode

If the state file is not found at the expected path, the dashboard switches to demo mode. Demo mode renders a sample operation with representative data so you can explore the dashboard layout and features without a running operation.

---

## What It Shows

### Operation Header

Displays the operation name, status (planning, executing, reviewing, complete), start time, elapsed duration, and the current execution mode (Subagent or Team).

### Task Dependency Graph

A visual graph showing all tasks and their dependency relationships. Nodes are color-coded by status:

- **Gray**: pending (dependencies not yet met)
- **Blue**: in progress (worker working)
- **Green**: complete (passed quality chain)
- **Yellow**: in revision (analyst findings triggered rework)
- **Red**: failed (exceeded revision cap or unrecoverable error)

Edges show dependency direction: an arrow from Task A to Task B means B depends on A.

### Task Details

Click any task node to see its full details: description, acceptance criteria, assigned worker, analyst findings, revision history, and current status.

### Event Stream

A chronological feed of operation events, newest first. Each event shows a timestamp, event type, and summary. This mirrors the Banh Mi Event Stream (MES) in a human-readable format.

### Cost Breakdown

A table showing token usage by worker, analyst, and operation phase. Includes input tokens, output tokens, and estimated cost at current model pricing.

---

## State File Schema

The `state.json` file uses the following schema:

```json
{
  "operation": {
    "id": "string",
    "name": "string",
    "status": "planning | executing | reviewing | complete | failed",
    "mode": "subagent | team",
    "startTime": "ISO 8601 timestamp",
    "endTime": "ISO 8601 timestamp or null",
    "description": "string"
  },
  "tasks": [
    {
      "id": "string",
      "name": "string",
      "description": "string",
      "status": "pending | dispatched | in_progress | complete | revision | failed",
      "assignee": "string (worker name or null)",
      "dependencies": ["string (task IDs)"],
      "acceptanceCriteria": ["string"],
      "findings": [
        {
          "analyst": "string (code-analyst | visual-analyst)",
          "severity": "BLOCKER | HIGH | MEDIUM | LOW",
          "message": "string",
          "file": "string or null",
          "line": "number or null"
        }
      ],
      "revisions": [
        {
          "round": "number (1 or 2)",
          "trigger": "string (analyst finding summary)",
          "outcome": "string (resolved | persisted | escalated)"
        }
      ],
      "startTime": "ISO 8601 timestamp or null",
      "endTime": "ISO 8601 timestamp or null"
    }
  ],
  "events": [
    {
      "timestamp": "ISO 8601 timestamp",
      "type": "string (task_dispatched | task_completed | finding_added | revision_started | operation_complete | ...)",
      "summary": "string",
      "taskId": "string or null",
      "metadata": {}
    }
  ],
  "cost": {
    "totalInputTokens": "number",
    "totalOutputTokens": "number",
    "byWorker": {
      "worker-name": {
        "inputTokens": "number",
        "outputTokens": "number"
      }
    },
    "byPhase": {
      "sweep": { "inputTokens": "number", "outputTokens": "number" },
      "execution": { "inputTokens": "number", "outputTokens": "number" },
      "analysis": { "inputTokens": "number", "outputTokens": "number" },
      "revision": { "inputTokens": "number", "outputTokens": "number" }
    }
  }
}
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `operation.id` | string | Unique operation identifier |
| `operation.name` | string | Human-readable operation name |
| `operation.status` | enum | Current lifecycle phase |
| `operation.mode` | enum | Execution backend: subagent or team |
| `operation.startTime` | ISO 8601 | When the operation began |
| `operation.endTime` | ISO 8601 or null | When the operation finished, null if still running |
| `tasks[].id` | string | Unique task identifier |
| `tasks[].status` | enum | Current task state |
| `tasks[].dependencies` | string[] | IDs of tasks that must complete before this one dispatches |
| `tasks[].findings` | object[] | Analyst findings attached to this task |
| `tasks[].revisions` | object[] | Revision cycle history |
| `events[].type` | string | Event type identifier |
| `cost.byWorker` | object | Token usage broken down by worker name |
| `cost.byPhase` | object | Token usage broken down by operation phase |

---

## Coordinator Integration

The Coordinator writes the state file after each significant event during the operation. The write cadence includes:

- Operation creation (initial state)
- Each task dispatch
- Each task completion
- Each analyst finding
- Each revision cycle start and end
- Operation completion or failure

The Coordinator writes the entire state atomically (write to a temporary file, then rename) to prevent the dashboard from reading a partially written file.

---

## Customization

The dashboard is a single HTML file with embedded CSS and JavaScript. All customization is done by editing the file directly.

### Refresh Interval

Find the `REFRESH_INTERVAL_MS` constant near the top of the script section:

```javascript
const REFRESH_INTERVAL_MS = 2000;
```

Change the value to your preferred interval in milliseconds.

### Colors

Task status colors are defined in the CSS section as CSS custom properties:

```css
:root {
  --status-pending: #9ca3af;
  --status-in-progress: #3b82f6;
  --status-complete: #22c55e;
  --status-revision: #eab308;
  --status-failed: #ef4444;
}
```

Edit these values to match your preferred color scheme.

### State File Path

The default state file path is configured in the script section:

```javascript
const STATE_FILE_PATH = '.claude/banhmi/operations/current/state.json';
```

Change this if your operations use a different directory structure.
