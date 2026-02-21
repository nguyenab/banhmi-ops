# Banh Mi Ops Architecture

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## System Overview

Banh Mi Ops is a multi-agent orchestration framework built on Claude Code. It decomposes complex software operations into discrete tasks, delegates them to specialized subagents, and enforces quality through a structured analyst chain.

The system has three principal actor types:

- **Coordinator** -- the main Claude Code session that the Lead (human user) interacts with directly. It owns the operation lifecycle, delegates tasks, and aggregates results.
- **Workers** -- subagents spawned by the Coordinator to execute individual tasks. Each worker is specialized for a platform or concern (Drupal theming, React components, API integration, etc.).
- **Reviewers** -- subagents that perform post-execution quality review. They never modify code directly; they produce findings that feed back into revision cycles.

The Lead initiates operations through the Coordinator, which plans, delegates, reviews, and reports.

---

## Layer Architecture

Banh Mi Ops is organized into four layers, each with a distinct responsibility.

### 1. Skills Layer

Skills are Claude Code slash commands that serve as entry points. They parse Lead intent, load context, and hand off to the appropriate agent or workflow.

- `/banhmi` -- primary entry point, launches the Operations Wizard
- `/sweep` -- triggers intelligence reconnaissance
- `/debrief` -- generates operation summary reports

### 2. Agents Layer

Agents are markdown-defined personas with specialized instructions. Each agent file contains frontmatter metadata, a specialization section, intake protocols, execution rules, and debrief format.

- **Workers** live in `agents/` (core) or `teams/<platform>/` (platform-specific)
- **Reviewers** live in `agents/` (e.g., `code-reviewer.md`, `visual-reviewer.md`, `report-writer.md`)

### 3. Scripts Layer

Node.js and shell scripts that handle automation tasks the agents cannot perform natively.

- `scripts/setup.sh` -- installs Banh Mi Ops into a Claude Code environment
- `scripts/setup-permissions.sh` -- configures MCP permissions for a division
- `scripts/extract-tokens.sh` -- extracts token usage from session logs
- `scripts/render-report.js` -- renders debrief JSON into an HTML report

### 4. Templates Layer

Reusable templates for structured output.

- `templates/operation-debrief.html` -- HTML template for rendering operation debrief reports

---

## Team System

Divisions group workers by platform or technology stack. Each division is a directory under `teams/` containing worker definitions and platform-specific protocols.

```
teams/
  drupal/
    backend-worker.md
    frontend-worker.md
    fullstack-worker.md
  generic/
    backend-worker.md
    frontend-worker.md
    fullstack-worker.md
```

Each division contains worker Markdown files directly in its directory. Workers are specialized for the division's platform and follow the same system prompt format as core agents.

---

## Inter-Worker Delegation Patterns

A core architectural constraint: **workers never spawn other workers.** All delegation flows through the Coordinator.

```
Director
  └─► Coordinator
        ├─► Worker A (Task 1)
        ├─► Worker B (Task 2)
        ├─► Worker C (Task 3)
        ├─► Code Reviewer (review all)
        ├─► Visual Reviewer (validate UI)
        └─► Report Writer (summarize)
```

This flat delegation model ensures:

1. The Coordinator maintains full visibility of all task states.
2. No circular or recursive spawning can occur.
3. Token budgets are controlled at a single point.
4. The Lead can interrupt or redirect any worker through the Coordinator.

---

## Post-Execution Quality Chain

After workers complete their tasks, the Coordinator initiates a quality chain.

### Step 1: Code Reviewer

Reviews all code changes produced by workers. Checks for:

- Adherence to project protocols
- Code style and convention compliance
- Potential regressions
- Security concerns

Produces a structured findings report with severity levels:

- **BLOCKER**: Security, crash, data loss. Must fix.
- **HIGH**: Bug, logic error, standards violation. Should fix.
- **MEDIUM**: Code smell, maintainability concern. Recommended.
- **LOW**: Style nit. Optional.

### Step 2: Visual Reviewer

If the operation involved UI changes, the Visual Reviewer uses a browser (via Playwright MCP) to validate the rendered output. Checks for:

- Layout correctness
- Responsive behavior
- Visual regressions
- Accessibility issues

### Step 3: Revision Cycle

If reviewers produce BLOCKER findings, the Coordinator may send tasks back to workers for correction. The revision cycle is capped at **2 rounds** to prevent infinite loops and control costs.

### Step 4: Report Writer

After revisions (or if none were needed), the Report Writer compiles the final operation debrief, including task outcomes, analyst findings, revisions applied, and overall status.

---

## Data Flow

### Input Data

- **prd.json** -- the operation plan, generated by the Operations Wizard or provided by the Lead. Contains task definitions, acceptance criteria, and division assignments.
- **recon-data/** -- reconnaissance data from sweeps. YAML intelligence cards describing project structure, dependencies, and component inventories.
- **behavioral-notes.md** -- accumulated knowledge about the project's patterns, preferences, and quirks. Persists across operations to avoid redundant exploration.

### Output Data

- **debrief.json** -- structured operation report containing task results, analyst findings, token usage, and timing data.
- **events/*.ndjson** -- Banh Mi Event Stream logs (see EVENT_STREAM.md).

### Flow Sequence

```
Lead intent
  → Operations Wizard (generates prd.json)
    → Coordinator (reads prd.json + recon-data)
      → Workers (execute tasks, read/write project files)
        → Code Reviewer (reviews changes)
          → Visual Reviewer (validates UI, optional)
            → Revision Cycle (if needed, max 2 rounds)
              → Report Writer (compiles debrief.json)
                → Director (receives formatted report)
```

---

## Model Tier Allocation

Banh Mi Ops uses three model tiers to balance capability against cost.

| Tier | Model | Use Case | Rationale |
|------|-------|----------|-----------|
| Recon | Haiku | Sweeps, file scanning, indexing | High speed, low cost, sufficient for pattern matching |
| Analysis | Sonnet | Reviewers, planning, code review | Strong reasoning at moderate cost |
| Implementation | Opus | Workers, complex code generation | Maximum capability for production code |

The Coordinator itself runs on whatever model the Lead's Claude Code session uses (typically Opus). Subagent model tiers are specified in the agent definition frontmatter.

### Per-Role Model Assignment

| Role | Model | Rationale |
|------|-------|-----------|
| Workers | opus | Complex code generation |
| Code Reviewer | sonnet | Review, not generation |
| Visual Reviewer | sonnet | Observation and reporting |
| Report Writer | sonnet | Summary and synthesis |
| Planner | sonnet | Planning and decomposition |
| Testing Worker | opus | Test writing needs code gen |
| Sweep | haiku | Lightweight scanning |

---

## Dependency-Driven Dispatch

Tasks dispatch as soon as their dependencies clear, not in rigid waves. The Coordinator maintains the full dependency graph and monitors task completion events. When a task completes and passes the quality chain, the Coordinator immediately evaluates which downstream tasks now have all their dependencies satisfied and dispatches them without waiting for an entire wave to finish.

This approach maximizes parallelism in both Subagent Mode and Team Mode. In Subagent Mode, the Coordinator dispatches the next eligible worker as soon as one finishes. In Team Mode, teammates self-claim newly eligible tasks from the shared task list. The result is the same: no idle time between waves, and tasks with independent dependency branches execute concurrently.

---

## Dual Execution Modes

Banh Mi Ops supports two execution backends that share the same planning, quality chain, and debrief infrastructure.

**Subagent Mode (default)**

- The Coordinator spawns workers as subagents using Claude Code's native subagent capability.
- Lower cost: roughly 1x baseline token usage.
- Workers execute sequentially or in small batches.
- All coordination flows through the Coordinator.
- Best for operations with 1 to 5 tasks.

**Team Mode (Claude Code Agent Teams)**

- The Coordinator acts as team lead and publishes tasks to a shared task list.
- Teammates self-claim tasks as dependencies clear.
- Higher cost: approximately 7x baseline token usage.
- True parallelism with peer-to-peer communication between teammates.
- Best for operations with 6 or more tasks and significant parallelism in the dependency graph.

Team Mode requires setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in the Claude Code settings environment. See [AGENT_TEAMS.md](AGENT_TEAMS.md) for full details.

---

## Context Handoff Protocol

When an worker completes a task, it produces a standardized debrief that the Coordinator uses to inform downstream workers and reviewers. The debrief follows a structured format with four sections:

- **files_changed**: A list of all files created, modified, or deleted during the task. Each entry includes the file path and a brief description of the change.
- **patterns_observed**: Conventions, patterns, or architectural decisions the worker discovered or followed during execution. These propagate to downstream workers to maintain consistency.
- **context_for_reviewers**: Information the Code Reviewer and Visual Reviewer need to perform their review effectively. Includes what to focus on, known tradeoffs, and any deviations from the original plan.
- **blockers_for_downstream**: Issues or conditions that downstream tasks should be aware of. Includes incomplete work, assumptions made, or environmental requirements.

This protocol ensures that each handoff carries structured, actionable context rather than freeform prose. The Coordinator injects relevant sections into downstream worker prompts based on the dependency graph.

---

## Smart Revision Decisions

When the Code Reviewer or Visual Reviewer produces findings, the Coordinator does not automatically trigger a full revision cycle. Instead, it evaluates the findings against a decision matrix to determine the appropriate response.

| Decision | Criteria | Action |
|----------|----------|--------|
| **ACCEPT** | All findings are LOW severity, or findings are informational only. | Mark the task as complete. Attach findings to the record for reference. |
| **TARGETED_REVISION** | Findings include MEDIUM severity items that affect a small, well-defined scope. No BLOCKER or HIGH findings. | Re-dispatch the worker with only the specific findings to address. The worker fixes the targeted issues without re-implementing the full task. |
| **FULL_REVISION** | Findings include HIGH severity items, or MEDIUM items that span multiple files or affect architecture. | Re-dispatch the worker with the full set of findings. The worker may need to rethink its approach. Counts toward the 2-round revision cap. |
| **ESCALATE** | Findings include BLOCKER severity, or the task has already exhausted its revision rounds (2 maximum). | Pause the task and notify the Lead. The Coordinator presents the findings and asks for human guidance before proceeding. |

This matrix prevents unnecessary revision cycles for minor findings while ensuring serious issues are addressed promptly. It also provides a clear escalation path when automated resolution is insufficient.

---

## Diagrams

Architecture diagrams are maintained as D2 source files in `assets/diagrams/`. These include:

- `system-overview.d2` -- high-level actor relationships
- `delegation-flow.d2` -- task delegation sequence
- `quality-chain.d2` -- post-execution analyst pipeline
- `data-flow.d2` -- data artifact lifecycle
- `division-structure.d2` -- team pack organization

Render with the D2 CLI: `d2 assets/diagrams/system-overview.d2 assets/diagrams/system-overview.svg`

---

## Key Architectural Decisions

1. **Flat delegation only.** Workers cannot spawn subagents. This prevents runaway token consumption and maintains Coordinator authority.
2. **Capped revision cycles.** Two rounds maximum. If issues persist after two revisions, they are flagged for Director intervention.
3. **Stateless workers.** Each worker receives its full context at spawn time. It does not depend on the state of other workers.
4. **Structured output contracts.** All inter-agent communication uses defined schemas (JSON, YAML). No freeform handoffs.
5. **Division isolation.** Division-specific protocols do not leak into other divisions. A Drupal worker never applies React conventions.

---

## Further Reading

- [INSTALLATION.md](INSTALLATION.md) -- setup and deployment
- [EVENT_STREAM.md](EVENT_STREAM.md) -- event stream specification
- [SWEEP.md](SWEEP.md) -- reconnaissance methodology
- [TEAM_PACKS.md](TEAM_PACKS.md) -- creating custom divisions
- [CUSTOMIZATION.md](CUSTOMIZATION.md) -- extending the framework
- [AGENT_TEAMS.md](AGENT_TEAMS.md) -- using Claude Code Agent Teams with Banh Mi Ops
- [DASHBOARD.md](DASHBOARD.md) -- live dashboard setup and state file schema
