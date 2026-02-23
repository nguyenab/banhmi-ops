# Banh Mi Event Stream (MES)

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## Overview

The Banh Mi Event Stream (MES) is a structured logging system that records all significant events during an operation. It provides real-time observability into worker lifecycles, analyst findings, task state transitions, and operation-level milestones.

MES uses a simple, universal format: newline-delimited JSON (NDJSON). Any tool that can read NDJSON can consume the stream, making it straightforward to build dashboards, notifications, and audit trails.

---

## Format

Each line in an MES file is a self-contained JSON object. Files use the `.ndjson` extension.

### Schema

```json
{
  "timestamp": "2026-03-28T14:32:01.042Z",
  "event_type": "worker.started",
  "operation_id": "op-2026-03-28-1430",
  "source": "theme-worker",
  "payload": {},
  "sequence": 1
}
```

**Required fields:**

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 string | When the event occurred |
| `event_type` | string | Dot-notation event identifier |
| `operation_id` | string | ID of the parent operation |
| `source` | string | Name of the agent or system component that emitted the event |
| `payload` | object | Event-specific data (varies by type) |
| `sequence` | integer | Monotonically increasing counter within the operation |

---

## Event Types

### Operation Lifecycle

| Event Type | Description |
|------------|-------------|
| `operation.planned` | prd.json has been generated and accepted |
| `operation.started` | Coordinator has begun delegating tasks |
| `operation.completed` | All tasks and quality checks are done |
| `operation.aborted` | Director or system halted the operation |

### Task Lifecycle

| Event Type | Description |
|------------|-------------|
| `task.queued` | Task is defined and waiting for an worker |
| `task.assigned` | Task has been delegated to a specific worker |
| `task.accepted` | Worker acknowledged the task and began work |
| `task.completed` | Worker finished and produced a debrief |
| `task.failed` | Worker encountered an unrecoverable error |
| `task.revision_requested` | Analyst findings require a revision |
| `task.revision_completed` | Worker completed the revision |

### Worker Lifecycle

| Event Type | Description |
|------------|-------------|
| `worker.started` | Subagent has been spawned |
| `worker.progress` | Worker reports intermediate progress |
| `worker.completed` | Subagent finished and returned results |
| `worker.error` | Subagent encountered an error |

### Analyst Events

| Event Type | Description |
|------------|-------------|
| `analyst.started` | Analyst review has begun |
| `analyst.finding` | A single finding from the analyst |
| `analyst.completed` | Analyst finished the review |

### Sweep Events

| Event Type | Description |
|------------|-------------|
| `sweep.started` | Reconnaissance sweep initiated |
| `sweep.module_scanned` | A single module/component scan completed |
| `sweep.completed` | All scans finished, recon cards written |

---

## Event Storage

MES files are stored in the `.claude/events/` directory, organized by operation:

```
.claude/events/
  op-2026-03-28-1430.ndjson
  op-2026-03-28-1545.ndjson
  op-2026-03-29-0900.ndjson
```

Each operation produces one NDJSON file. The file is append-only during the operation and becomes immutable once the operation completes.

---

## Consumer Model

MES is designed for loose coupling. The Coordinator writes events; consumers read them independently. There is no subscription mechanism built in. Instead, consumers poll the file or watch it with standard filesystem tools.

### Reading Events

Any NDJSON-capable tool works:

```bash
# Stream events as they happen
tail -f .claude/events/op-2026-03-28-1430.ndjson | jq .

# Filter for analyst findings only
cat .claude/events/op-2026-03-28-1430.ndjson | jq 'select(.event_type == "analyst.finding")'

# Count events by type
cat .claude/events/op-2026-03-28-1430.ndjson | jq -r '.event_type' | sort | uniq -c
```

---

## Example Consumers

### Slack Webhook

A simple Node.js script that watches for operation events and posts to a Slack channel:

```javascript
// consumers/slack-webhook.js
const fs = require('fs');
const https = require('https');

const WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;
const eventFile = process.argv[2];

const tail = fs.watch(eventFile, () => {
  // Read new lines and POST to Slack
  // Filter for high-priority events: operation.completed,
  // analyst.finding (critical), task.failed
});
```

### Discord Webhook

Same pattern as Slack, adapted for Discord's webhook payload format. Filter for events worth notifying on and format them as Discord embeds.

### CLI Dashboard

A terminal UI that reads the NDJSON stream and displays a live operation status board:

```bash
# Hypothetical usage
npx banhmi-dashboard .claude/events/op-2026-03-28-1430.ndjson
```

### Custom Visualizer

Since MES is standard NDJSON, you can pipe it into any visualization tool that accepts structured JSON, including web-based dashboards, Grafana (via a file exporter), or custom reporting pipelines.

---

## Event Payload Examples

### operation.planned

```json
{
  "timestamp": "2026-03-28T14:30:00.000Z",
  "event_type": "operation.planned",
  "operation_id": "op-2026-03-28-1430",
  "source": "station-chief",
  "payload": {
    "task_count": 4,
    "division": "drupal",
    "estimated_workers": 3
  },
  "sequence": 1
}
```

### worker.started

```json
{
  "timestamp": "2026-03-28T14:31:12.500Z",
  "event_type": "worker.started",
  "operation_id": "op-2026-03-28-1430",
  "source": "theme-worker",
  "payload": {
    "task_id": "task-001",
    "model": "opus",
    "division": "drupal"
  },
  "sequence": 3
}
```

### analyst.finding

```json
{
  "timestamp": "2026-03-28T14:45:33.200Z",
  "event_type": "analyst.finding",
  "operation_id": "op-2026-03-28-1430",
  "source": "code-analyst",
  "payload": {
    "severity": "warning",
    "file": "web/themes/custom/mytheme/mytheme.theme",
    "line": 42,
    "description": "Unused variable $node_view_mode in preprocess function",
    "suggestion": "Remove the variable or use it in the template suggestion logic"
  },
  "sequence": 12
}
```

### operation.completed

```json
{
  "timestamp": "2026-03-28T15:02:10.800Z",
  "event_type": "operation.completed",
  "operation_id": "op-2026-03-28-1430",
  "source": "station-chief",
  "payload": {
    "tasks_completed": 4,
    "tasks_failed": 0,
    "revision_cycles": 1,
    "analyst_findings": 3,
    "duration_seconds": 1930
  },
  "sequence": 28
}
```

---

## Further Reading

- [ARCHITECTURE.md](ARCHITECTURE.md) -- how MES fits into the system
- [INTEGRATIONS.md](INTEGRATIONS.md) -- webhook and CI/CD consumers
- [ITERATION.md](ITERATION.md) -- using MES data for benchmarking
