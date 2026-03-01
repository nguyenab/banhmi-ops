# Usage Guide

Detailed walkthrough for using Banh Mi Ops, from first launch through operation completion.

## Table of Contents

- [Getting Started](#getting-started)
- [The Operation Wizard](#the-operation-wizard)
- [Execution Modes](#execution-modes)
- [Working with Sweeps](#working-with-sweeps)
- [Task Management](#task-management)
- [The Quality Chain](#the-quality-chain)
- [Debrief and Reporting](#debrief-and-reporting)
- [Team Packs](#division-packs)
- [Cheat Sheet](#cheat-sheet)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Getting Started

After installing Banh Mi Ops (see [README.md](README.md)), open any project in Claude Code:

```bash
cd ~/your-project
claude
```

Type `/banhmi` to launch the operation wizard.

### Verify Installation

Before your first run, confirm that files are in place:

```bash
# Check global install
ls ~/.claude/commands/banhmi.md
ls ~/.claude/agents/station-chief.md
ls ~/.claude/scripts/setup.sh

# Check local install (if used)
ls .claude/commands/banhmi.md
```

If any files are missing, re-run the installer:

```bash
bash ~/banhmi-ops/scripts/setup.sh --global
```

---

## The Operation Wizard

The `/banhmi` command starts an interactive wizard that walks you through operation planning.

### Step 1: Describe the Feature

The Coordinator asks you to describe what you want to build or change. Be as specific as helpful, but you do not need to specify implementation details. Good examples:

- "Add a user profile page with avatar upload, bio field, and activity history."
- "Refactor the notification system to use a queue instead of synchronous dispatch."
- "Fix the checkout flow where discount codes are not applied to subscription items."

### Step 2: Sweep

The Coordinator launches a codebase reconnaissance scan. This takes a few moments and produces a structured snapshot of your project, covering:

- Framework and language detection
- Key directories and entry points
- Dependency inventory
- Coding conventions observed
- Test infrastructure
- Risk areas related to your described feature

You can review the sweep output or let the Coordinator proceed.

### Step 3: Task Decomposition

Based on your description and the sweep results, the Coordinator proposes a set of tasks. Each task includes:

- **Title** and brief description
- **Acceptance criteria** (what "done" means)
- **Assigned worker** (which agent will handle it)
- **Dependencies** (tasks that must complete first)

You can approve the plan, modify tasks, add tasks, remove tasks, or reorder them.

### Step 4: Choose Execution Mode

- **Oversight Mode:** You review and approve each task before it is dispatched. Best for sensitive changes or when learning the system.
- **Autonomous Mode:** All tasks execute in sequence without pausing. Results are presented when the wave completes.

### Step 5: Execution

Tasks are dispatched to their assigned workers. Each worker receives the sweep context, task instructions, acceptance criteria, and the standing protocols.

In Oversight Mode, you see each task's plan before execution and can modify or skip it.

### Step 6: Quality Chain

After each task completes, the Code Reviewer reviews the changes. If the task has visual impact, the Visual Reviewer also validates in the browser. Findings are reported with severity levels.

### Step 7: Debrief

When all tasks are complete (or you end the operation early), the Coordinator produces a debrief summary. Use `/debrief` to render the full HTML report.

---

## Execution Modes

### Oversight Mode

In Oversight Mode, the Coordinator pauses before each task dispatch:

```
[Coordinator] Task 2 of 5: "Create UserProfile component"
  Worker: react-implementer
  Acceptance: Component renders user data, handles loading state,
              includes avatar and bio sections.

  Approve? (yes / modify / skip / abort)
```

Options:
- **yes** - Dispatch the task as described.
- **modify** - Edit the task description, criteria, or worker assignment.
- **skip** - Skip this task and move to the next.
- **abort** - End the operation. Completed tasks remain, pending tasks are cancelled.

### Autonomous Mode

In Autonomous Mode, all tasks execute without pausing. The Coordinator reports progress as each task completes:

```
[Coordinator] Task 1/5 complete: "Set up database migration" [OK]
[Coordinator] Task 2/5 complete: "Create UserProfile component" [OK]
[Coordinator] Task 3/5 dispatching: "Add avatar upload endpoint"
...
```

At the end, all results and analyst findings are presented together.

### Switching Modes

You can switch from Oversight to Autonomous mid-operation by telling the Coordinator:

```
Switch to autonomous mode for the remaining tasks.
```

Or from Autonomous to Oversight:

```
Pause. Switch to oversight mode.
```

---

## Working with Sweeps

### Standalone Sweep

Run a sweep without starting a full operation:

```
/sweep
```

This is useful for:
- Orienting yourself in an unfamiliar codebase
- Checking project state before planning
- Generating context you can reference in manual Claude Code sessions

### Sweep Output

The sweep produces structured data covering:

| Section | Contents |
|---------|----------|
| Project type | Framework, language, platform detection |
| Structure | Key directories, entry points, configuration files |
| Dependencies | Packages, versions, notable libraries |
| Conventions | Naming patterns, file organization, coding style |
| Tests | Test framework, test file locations, run commands |
| Risks | Areas of complexity or fragility related to the task |

### Customizing Sweep Depth

You can ask the Coordinator to focus the sweep:

```
Run a sweep focused on the authentication system and user models.
```

Or to scan broadly:

```
Run a full project sweep. I need the complete picture.
```

---

## Task Management

### Task States

| State | Meaning |
|-------|---------|
| **Pending** | Not yet dispatched |
| **In Progress** | Worker is working on it |
| **Complete** | Finished and passed quality chain |
| **Failed** | Worker encountered an error |
| **Skipped** | Director chose to skip this task |
| **Revision** | Re-dispatched with analyst findings |

### Checking Status

At any point during an operation, use:

```
/status
```

This shows:
- Operation title and mode
- Task list with current states
- Pending analyst reviews
- Token usage so far

### Adding Tasks Mid-Operation

You can add tasks during execution:

```
Add a task: Write unit tests for the UserProfile component.
```

The Coordinator will slot it into the task list at the appropriate position.

### Cancelling an Operation

To stop an operation early:

```
Abort the operation.
```

Completed tasks and their changes remain in place. Pending tasks are cancelled. The debrief will reflect the partial completion.

---

## The Quality Chain

### Code Reviewer

The Code Reviewer reviews every completed task. It examines:

- Correctness of the implementation
- Adherence to project conventions and protocols
- Security concerns (input validation, output escaping, etc.)
- Performance implications
- Test coverage

Findings are categorized by severity:

| Severity | Meaning |
|----------|---------|
| **Critical** | Must be fixed. Blocks task completion. |
| **Warning** | Should be fixed. May be deferred with justification. |
| **Info** | Observation or suggestion. No action required. |
| **Pass** | No issues found. |

### Visual Reviewer

For tasks with UI changes, the Visual Reviewer opens the result in a browser and checks:

- Layout correctness at standard viewpoints
- Responsive behavior
- Basic accessibility (contrast, labels, focus states)
- Functional behavior (clicks, navigation, form submission)

### Revision Cycles

If the Code Reviewer or Visual Reviewer flags Critical or Warning findings, the Coordinator triggers a Revision Cycle:

1. The original worker receives the analyst findings.
2. The worker addresses the findings and resubmits.
3. The reviewers re-review.

A maximum of two revision rounds are allowed per task. If issues persist after two rounds, the task is marked complete with findings attached, and the Lead is notified.

---

## Debrief and Reporting

### Generating a Debrief

After an operation completes (or at any point):

```
/debrief
```

This produces a JSON record of the full operation and renders it into an HTML report.

### Report Contents

The HTML report includes:

- **Operation header** with title, status, and timestamp
- **Executive summary** of what was accomplished
- **Task cards** showing status, worker, deliverables, and duration
- **Cost tracking** with token usage by model
- **Timeline** of key events
- **Analyst findings** with severity and file references
- **Overall assessment** from the Coordinator

### Manual Report Rendering

If you have a debrief JSON file and want to render it separately:

```bash
node ~/.claude/scripts/render-report.js debrief.json report.html
```

Open `report.html` in any browser to view the styled report.

### Token Extraction

To extract token usage from Claude Code session logs:

```bash
# Summary of most recent session
bash ~/.claude/scripts/extract-tokens.sh --latest --summary

# NDJSON output for processing
bash ~/.claude/scripts/extract-tokens.sh --latest
```

---

## Team Packs

### Using Divisions

Divisions are installed at setup time:

```bash
bash ~/banhmi-ops/scripts/setup.sh --global --team drupal
bash ~/banhmi-ops/scripts/setup-permissions.sh --global --team drupal
```

Multiple divisions can coexist:

```bash
bash ~/banhmi-ops/scripts/setup.sh --global --team drupal --team react
```

### Available Divisions

**Generic (always installed)**
- General-purpose implementer for any language or framework.

**Drupal**
- Drupal-specific implementer with knowledge of module development, Drush commands, render arrays, configuration management, and Drupal coding standards.
- Adds permissions for `drush`, `phpunit`, `phpcs`, and related tools.

**React**
- React-specific implementer with knowledge of hooks, component architecture, state management patterns, and testing with Jest/React Testing Library.
- Adds permissions for `npx`, `npm test`, `npm run dev`, and related tools.

### Building Your Own Division

Create a new directory under `teams/`:

```
teams/
  your-division/
    agents/
      your-division-implementer.md
    commands/
      your-division-command.md
```

The worker Markdown file should include:
- A clear system prompt defining the agent's specialization
- Platform-specific knowledge and constraints
- References to relevant protocols

Register any additional permissions by adding a section to `setup-permissions.sh`.

---

## Cheat Sheet

| Action | Command / Instruction |
|--------|----------------------|
| Start an operation | `/banhmi` |
| Run a sweep only | `/sweep` |
| Check operation status | `/status` |
| Generate debrief report | `/debrief` |
| Approve a task (Oversight) | `yes` |
| Modify a task (Oversight) | `modify` then describe changes |
| Skip a task (Oversight) | `skip` |
| Abort the operation | `abort` or "Abort the operation" |
| Switch to autonomous | "Switch to autonomous mode" |
| Switch to oversight | "Switch to oversight mode" |
| Add a task mid-operation | "Add a task: [description]" |
| Focus the sweep | "Run a sweep focused on [area]" |
| Render report manually | `node ~/.claude/scripts/render-report.js data.json out.html` |
| Extract token usage | `bash ~/.claude/scripts/extract-tokens.sh --latest --summary` |

---

## Examples

### Example 1: Adding a Feature (Oversight Mode)

```
You: /banhmi

Coordinator: What would you like to build?

You: Add a contact form to the marketing site. It should have name, email,
     message fields, client-side validation, and send submissions to the
     existing /api/contact endpoint.

Coordinator: Running sweep...
  [Sweep complete. React 18 project, Tailwind CSS, Vitest for testing.]

Coordinator: Proposed tasks:
  1. Create ContactForm component with validation
  2. Add form submission handler with error states
  3. Write unit tests for ContactForm
  4. Add ContactForm to the /contact page route

  Mode: Oversight / Autonomous?

You: Oversight

Coordinator: Task 1/4: "Create ContactForm component with validation"
  Worker: react-implementer
  Approve?

You: yes

  [Task executes, Code Reviewer reviews...]

Coordinator: Task 1 complete. Code Reviewer: Pass.
  Task 2/4: "Add form submission handler"
  Approve?

You: yes

  [Continues through all tasks...]

Coordinator: Operation complete. 4/4 tasks passed. /debrief for full report.
```

### Example 2: Bug Fix (Autonomous Mode)

```
You: /banhmi

Coordinator: What would you like to build?

You: Fix the bug where pagination on the blog listing page resets to page 1
     when a filter is applied. The URL query params are not preserved.

Coordinator: Running sweep...
  [Sweep complete. Identifies BlogList component, useSearchParams hook,
   filter handler in BlogFilters component.]

Coordinator: Proposed tasks:
  1. Fix BlogFilters to preserve existing query params when updating filters
  2. Add test case for filter + pagination interaction

  Mode: Oversight / Autonomous?

You: Autonomous

  [Both tasks execute, reviewers review...]

Coordinator: Operation complete. 2/2 tasks passed.
  Code Reviewer: Pass on both tasks.
  Summary: Fixed query param handling in BlogFilters.handleFilterChange().
           Added integration test verifying pagination state persists
           across filter changes.
```

### Example 3: Drupal Module Task

```
You: /banhmi

Coordinator: What would you like to build?

You: Create a custom Drupal module that adds a "Related Content" block.
     It should display 3 nodes of the same content type as the current page,
     ordered by most recent, excluding the current node.

Coordinator: Running sweep...
  [Sweep complete. Drupal 10 project, custom theme, existing custom modules
   in web/modules/custom/.]

Coordinator: Proposed tasks:
  1. Scaffold module structure (info.yml, src directory)
  2. Create RelatedContent block plugin with entity query
  3. Add block template with proper render array
  4. Write kernel test for the entity query logic

  Mode?

You: Autonomous

  [Tasks execute with drupal-implementer worker...]
```

---

## Troubleshooting

### "Command not found: /banhmi"

The skill files are not installed. Re-run setup:

```bash
bash ~/banhmi-ops/scripts/setup.sh --global
```

Verify the file exists:

```bash
ls ~/.claude/commands/banhmi.md
```

### "Permission denied" errors during execution

Pre-authorize the required tools:

```bash
bash ~/banhmi-ops/scripts/setup-permissions.sh --global --team <your-division>
```

### Workers not spawning

Ensure agent files are in the correct location:

```bash
ls ~/.claude/agents/
```

Claude Code looks for agent files in `.claude/agents/` (local) and `~/.claude/agents/` (global).

### Report rendering fails

Install the npm dependencies:

```bash
cd ~/.claude/scripts && npm install
```

Or from the source:

```bash
cd ~/banhmi-ops/scripts && npm install
```

### Sweep takes too long

For very large codebases, focus the sweep:

```
Run a sweep focused on the src/auth/ directory and related tests.
```

### Token usage seems high

Use the extraction script to audit:

```bash
bash ~/.claude/scripts/extract-tokens.sh --latest --summary
```

Consider using Autonomous Mode for well-understood tasks (fewer back-and-forth interactions) and scoping operations to smaller feature increments.

---

## Next Steps

- Read the [Protocols](protocols.md) to understand the standing coding directives.
- Explore the worker files in `agents/` to see how each agent is configured.
- Try a small operation first to get familiar with the workflow before tackling large features.
