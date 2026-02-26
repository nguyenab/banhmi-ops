# Banh Mi Ops Integrations

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## Overview

Banh Mi Ops produces structured event data (MES) and operation debriefs that can be consumed by external systems. Integrations are built as consumers of these outputs, not as modifications to the core framework.

This document covers integration patterns for notifications, dashboards, CI/CD, and headless automation.

---

## Slack Integration

Post operation events to a Slack channel using an incoming webhook.

### Setup

1. Create a Slack incoming webhook at [api.slack.com/messaging/webhooks](https://api.slack.com/messaging/webhooks).
2. Store the webhook URL in an environment variable:

```bash
export BANHMI_SLACK_WEBHOOK=https://hooks.slack.com/services/T00/B00/xxxx
```

3. Run the Slack consumer alongside your operation:

```bash
node scripts/consumers/slack-webhook.js .claude/events/<operation>.ndjson &
```

### Event Filtering

The Slack consumer should filter for high-signal events to avoid noise:

- `operation.completed` -- summary of the finished operation
- `task.failed` -- immediate notification of failures
- `analyst.finding` where severity is `critical` -- urgent quality issues
- `operation.aborted` -- the operation was halted

### Message Format

```json
{
  "text": "Banh Mi Ops Operation Completed",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Operation:* op-2026-03-28-1430\n*Tasks:* 4 completed, 0 failed\n*Revisions:* 1 cycle\n*Duration:* 32 minutes"
      }
    }
  ]
}
```

---

## Discord Integration

Similar to Slack, using Discord webhooks.

### Setup

1. Create a Discord webhook in your server's channel settings (Integrations > Webhooks).
2. Store the webhook URL:

```bash
export BANHMI_DISCORD_WEBHOOK=https://discord.com/api/webhooks/xxxx/yyyy
```

3. Run the Discord consumer:

```bash
node scripts/consumers/discord-webhook.js .claude/events/<operation>.ndjson &
```

### Message Format

Discord webhooks accept a slightly different payload format, using embeds for structured content:

```json
{
  "embeds": [
    {
      "title": "Operation Completed",
      "color": 3066993,
      "fields": [
        { "name": "Operation", "value": "op-2026-03-28-1430", "inline": true },
        { "name": "Tasks", "value": "4 completed", "inline": true },
        { "name": "Duration", "value": "32 minutes", "inline": true }
      ]
    }
  ]
}
```

---

## Custom Webhook Consumers

Any HTTP endpoint that accepts POST requests can serve as a Banh Mi Ops event consumer. The pattern:

1. Watch the NDJSON event file for new lines.
2. Parse each new line as JSON.
3. Filter for relevant event types.
4. Transform the event payload into the target format.
5. POST to the webhook URL.

### Consumer Template

```javascript
// scripts/consumers/custom-webhook.js
const fs = require('fs');
const https = require('https');

const webhookUrl = process.env.BANHMI_WEBHOOK_URL;
const eventFile = process.argv[2];
const relevantEvents = ['operation.completed', 'task.failed', 'analyst.finding'];

let position = 0;

fs.watchFile(eventFile, { interval: 1000 }, () => {
  const content = fs.readFileSync(eventFile, 'utf8');
  const newContent = content.slice(position);
  position = content.length;

  newContent.split('\n').filter(Boolean).forEach(line => {
    const event = JSON.parse(line);
    if (relevantEvents.includes(event.event_type)) {
      postToWebhook(event);
    }
  });
});

function postToWebhook(event) {
  // Transform and POST the event to your endpoint
}
```

---

## CLI Dashboard

A terminal-based dashboard that displays live operation status by reading the MES stream.

### Concept

The dashboard reads NDJSON events and renders a live-updating terminal UI showing:

- Current operation status (planning, executing, reviewing, complete)
- Active workers and their task assignments
- Analyst findings as they arrive
- Token usage running total
- Elapsed time

### Implementation Approach

Use a Node.js terminal UI library (such as blessed or ink) to render the dashboard:

```bash
npx banhmi-dashboard .claude/events/op-2026-03-28-1430.ndjson
```

The dashboard tails the event file and updates the display on each new event. It exits when it receives an `operation.completed` or `operation.aborted` event.

This is a concept for community contribution. The base Banh Mi Ops framework provides the event data; the dashboard is a consumer built on top of it.

---

## CI/CD Integration

Banh Mi Ops operations can be triggered from CI/CD pipelines using Claude Code's headless capabilities.

### Use Cases

- **Post-merge testing:** After a PR merges, trigger a Banh Mi Ops testing operation to validate the changes.
- **Automated sweeps:** Run nightly sweeps to keep intelligence cards fresh.
- **Regression checking:** After deployment, run a Visual Reviewer pass to detect UI regressions.

### Pipeline Example (GitHub Actions)

```yaml
name: Banh Mi Ops Sweep
on:
  schedule:
    - cron: '0 2 * * *'  # Nightly at 2 AM

jobs:
  sweep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code
      - name: Run sweep
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude --headless --command "/sweep"
      - name: Upload intel
        uses: actions/upload-artifact@v4
        with:
          name: recon-data
          path: .claude/recon-data/
```

### Headless Mode

In CI/CD environments, Claude Code runs without interactive input. The `--headless` flag combined with `--command` passes the command directly. Operations that require Lead input (like the Operations Wizard) need a pre-built `prd.json` provided via `--resume`:

```bash
claude --headless --command "/banhmi --resume .claude/banhmi/operations/predefined/prd.json"
```

---

## Agent SDK Headless Mode

For programmatic integration beyond CI/CD, the Anthropic Agent SDK can drive Banh Mi Ops operations from application code.

### Concept

Instead of a human Director interacting through the CLI, an application acts as the Lead by:

1. Constructing a `prd.json` programmatically.
2. Spawning a Claude Code session via the Agent SDK.
3. Feeding the `/banhmi --resume` command.
4. Reading the debrief JSON and MES events for results.

This enables scenarios like:

- A project management tool automatically creating operations from tickets.
- A monitoring system triggering fix operations when issues are detected.
- A review tool running Code Reviewer on every commit.

### Integration Pattern

```javascript
const { Agent } = require('@anthropic-ai/agent-sdk');

async function runBanhmiOperation(prdPath) {
  const agent = new Agent({
    model: 'claude-sonnet-4-20250514',
    tools: ['claude-code'],
  });

  const result = await agent.run({
    command: `/banhmi --resume ${prdPath}`,
    headless: true,
  });

  return JSON.parse(
    fs.readFileSync('.claude/banhmi/operations/latest/debrief.json')
  );
}
```

This is an advanced integration pattern. It requires the Agent SDK and careful handling of authentication, timeouts, and error states.

---

## Further Reading

- [EVENT_STREAM.md](EVENT_STREAM.md) -- MES format and event types
- [ARCHITECTURE.md](ARCHITECTURE.md) -- system design for integration points
- [TESTING_OPERATIONS.md](TESTING_OPERATIONS.md) -- CI/CD testing patterns
