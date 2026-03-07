# Banh Mi Ops Agent Teams

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops
**Date:** 2026-03-29

---

## What Are Agent Teams?

Agent Teams is Claude Code's native multi-agent feature, released in February 2026. It allows a single Claude Code session to spawn multiple peer agents (teammates) that work in parallel on a shared task list. Unlike the default subagent model, where the Coordinator sequentially spawns and waits for each worker, Agent Teams enables true concurrent execution with peer-to-peer coordination.

In the Agent Teams model, one agent acts as the team lead while the others are teammates. The lead creates a shared task list, and teammates self-claim tasks as their dependencies clear. This maps naturally to how Banh Mi Ops already structures operations: a Coordinator coordinating workers across a dependency graph.

---

## When to Use Team Mode vs Subagent Mode

Banh Mi Ops supports two execution backends:

**Subagent Mode (default)**

- Best for 1 to 5 tasks.
- Lower token cost (roughly 1x baseline).
- The Coordinator spawns workers one at a time (or in small batches).
- Sufficient for focused operations where tasks are mostly sequential or have tight dependencies.
- No additional configuration required.

**Team Mode**

- Best for 6 or more tasks.
- Higher token cost (approximately 7x a single session).
- True parallelism: teammates execute concurrently, not sequentially.
- Cross-layer work benefits most: when backend, frontend, testing, and documentation tasks can all proceed at once.
- Parallel exploration: multiple teammates can investigate different approaches simultaneously.
- Peer-to-peer communication allows teammates to share discoveries without routing everything through the lead.

**Rule of thumb:** if the operation has fewer than six tasks, Subagent Mode is more cost-effective. If the operation has six or more tasks with independent branches in the dependency graph, Team Mode pays for itself in wall-clock time savings.

---

## How to Enable

Set the following environment variable in your Claude Code `settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

This can go in either `~/.claude/settings.json` (global) or `.claude/settings.json` (project-local). Once enabled, the Coordinator will detect the capability and offer Team Mode during operation planning.

---

## How It Works with Banh Mi Ops

When Team Mode is active, the operation lifecycle adapts as follows:

1. **Planning.** The Coordinator (team lead) decomposes the operation into tasks, exactly as in Subagent Mode. The task dependency graph is the same.

2. **Task list creation.** Instead of spawning subagents, the Coordinator publishes the tasks to a shared task list visible to all teammates.

3. **Self-claiming.** Teammates monitor the task list and self-claim tasks as soon as their dependencies clear. No central scheduling loop is needed; the dependency graph drives dispatch naturally.

4. **Execution.** Each teammate executes its claimed task using the same worker system prompts, protocols, and context injection that subagents would receive.

5. **Quality chain.** Completed tasks still pass through the Code Reviewer and Visual Reviewer. These can also be teammates rather than subagents.

6. **Debrief.** The Coordinator aggregates results from all teammates and produces the standard debrief report.

---

## Quality Gates via Hooks

Agent Teams supports hooks that fire on specific lifecycle events. Banh Mi Ops uses two:

- **TaskCompleted hook.** When a teammate marks a task as done, this hook triggers a Code Reviewer review of the completed work. The review findings are attached to the task record before it is considered closed.

- **TeammateIdle hook.** When a teammate finishes its current task and has no pending claims, this hook evaluates the remaining task list and assigns the next eligible task based on dependency state and teammate specialization.

These hooks are defined in the operation configuration and require no manual setup beyond enabling Team Mode.

---

## Plan Approval

To prevent teammates from making unreviewed changes, Banh Mi Ops enforces a plan approval workflow:

1. When a teammate claims a task, it first plans its approach in **read-only mode**. It can read files and analyze the codebase, but cannot write.
2. The teammate submits its plan to the team lead (Coordinator).
3. The Coordinator reviews and approves the plan, optionally adding constraints or modifications.
4. Only after approval does the teammate enter write mode and begin implementation.

This mirrors the Oversight Mode behavior from Subagent Mode, adapted for the parallel execution model.

---

## Best Practices

- **3 to 5 teammates.** Fewer than three underutilizes the parallelism. More than five increases coordination overhead and token cost without proportional speed gains.

- **5 to 6 tasks per teammate.** Each teammate should have enough work to stay busy through the operation. If a teammate runs out of tasks early, it idles and consumes tokens waiting.

- **Each teammate owns distinct files.** Assign tasks so that teammates work on different files or directories. File-level conflicts between teammates are the most common failure mode.

- **Avoid file conflicts.** If two tasks must modify the same file, make one depend on the other. Never allow concurrent writes to the same file.

- **Use specialization.** Assign backend tasks to backend teammates, frontend tasks to frontend teammates. This matches the division worker model and reduces context-switching overhead.

- **Monitor cost.** Team Mode uses roughly 7x the tokens of a single-agent session. For small operations, the cost may not be justified.

---

## Cost Considerations

Team Mode consumes approximately 7x the tokens of a single Subagent Mode session. This multiplier comes from:

- Each teammate maintains its own context window.
- The shared task list and coordination messages add overhead.
- Plan approval exchanges between teammates and the lead consume tokens.
- Idle teammates still consume tokens while waiting for dependencies to clear.

The cost is worth it when:

- The operation has 6 or more tasks with independent dependency branches.
- Wall-clock time matters more than token cost.
- The dependency graph has enough parallelism to keep multiple teammates busy simultaneously.

The cost is not worth it when:

- Tasks are mostly sequential (each depends on the previous).
- The operation is small (fewer than 6 tasks).
- Token budget is constrained.

---

## Display Modes

Agent Teams provides two ways to monitor teammate activity:

**In-process display**

- All teammates share a single terminal.
- Press `Shift+Down` to cycle through teammate views.
- The status bar shows which teammate is currently displayed and the overall task completion state.
- Best for quick monitoring on a single screen.

**Split panes**

- Each teammate runs in its own terminal pane.
- Works with tmux, iTerm2 split panes, or any terminal multiplexer.
- Each pane shows one teammate's live output.
- Best for detailed monitoring of parallel work.

---

## Limitations

Agent Teams is currently experimental. Known limitations:

- **No session resumption.** If the session ends (crash, disconnect, manual exit), the team cannot be resumed. You must start a new operation.
- **One team per session.** A Claude Code session can host at most one active team. You cannot run multiple teams simultaneously.
- **No nested teams.** A teammate cannot itself become a team lead and spawn sub-teammates. The hierarchy is flat: one lead, multiple teammates.
- **Experimental status.** The feature may change in future Claude Code releases. Pin your Claude Code version if stability is critical.
- **No cross-session teams.** Teammates must all be in the same Claude Code session. You cannot distribute teammates across multiple machines or terminals.
