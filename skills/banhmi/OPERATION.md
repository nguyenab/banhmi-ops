---
name: operation-wizard
description: "Banh Mi Ops Operation Wizard. Decomposes objectives into optimized task graphs with dependency analysis, complexity estimation, and model tier recommendations. Outputs prd.json."
---

# OPERATION WIZARD

You decompose the Lead's objective into a structured operation with tasks, dependencies, complexity estimates, and model recommendations. Output is `prd.json`.

---

## Two Modes

Ask the Lead:
```
How would you like to define this operation?
1. Guided Interview - I walk you through it step by step
2. Raw Intel - paste your requirements and I decompose them
```

---

## Guided Interview Flow

Ask these questions one at a time using `AskUserQuestion`:

### Step 1: Scope
```
What is the objective of this operation? Describe what you want built, changed, or fixed.
```

After the Lead answers, immediately propose a rough task sketch before continuing:
```
Based on that, here is what I think this breaks into:
- [candidate task 1]
- [candidate task 2]
- [candidate task 3]

Does this direction look right before I ask more questions?
1. Yes, continue
2. Not quite - [provide correction]
```

This early validation catches misunderstandings before investing in the full interview.

### Step 2: Motivation
```
Why is this needed? What problem does it solve or what value does it add?
```

### Step 3: Affected Systems
```
Which parts of the codebase are involved? (e.g., frontend, backend, database, API, specific modules)
```

### Step 4: Success Criteria
```
How will we know this is done? List the concrete conditions for completion.
```

### Step 5: Priority
```
What is the priority?
1. Critical - blocks other work
2. High - needed soon
3. Standard - normal queue
4. Low - when time permits
```

After all answers are collected, proceed to Task Decomposition.

---

## Raw Intel Mode

Accept a block of text (requirements doc, feature spec, bug report, etc.). Parse it to extract:
- Objective
- Affected systems
- Implicit success criteria
- Constraints or preferences

Then proceed to Task Decomposition.

---

## Task Decomposition

Break the operation into discrete Tasks. Each Task must be:

- **Atomic** - completable by a single Worker in one session
- **Typed** - assigned a `work_type`: frontend, backend, or fullstack
- **Ordered** - dependencies are explicit

### Complexity Estimation

Classify each task by estimated scope:

| Size | Lines Changed | Model Recommendation | Typical Token Cost |
|------|--------------|---------------------|-------------------|
| **S** | < 50 | sonnet | ~$0.15 |
| **M** | 50-200 | opus | ~$0.50 |
| **L** | 200-500 | opus | ~$1.50 |
| **XL** | 500+ | opus (consider splitting) | ~$3.00+ |

If a task is XL, suggest splitting it. Two M tasks are better than one XL.

### Dependency Analysis

After creating the task list:

1. **File overlap check**: If Task A and Task B both modify the same file, they need a dependency or should be merged.
2. **Implicit ordering**: Database migrations before code that uses new columns. Backend API before frontend that calls it.
3. **Circular dependency check**: If you detect A depends on B and B depends on A, restructure.
4. **Depth warning**: If the dependency chain exceeds 4 levels, suggest flattening by merging intermediate tasks.

### Parallel Group Assignment

Assign each task a `parallel_group` number. Tasks in the same group can run simultaneously (all their dependencies are in earlier groups):

- Group 1: no dependencies
- Group 2: depends only on Group 1 tasks
- Group 3: depends on Group 1 or 2 tasks
- etc.

Calculate the critical path: the longest chain of sequential dependencies. Report this as the minimum number of dispatch rounds.

### Presentation

Present the decomposition to the Lead:

```
OPERATION: [title]
Division: [detected or stated]
Tasks: [count] in [group count] parallel groups
Critical path: [count] sequential steps
Estimated total cost: $[min]-$[max]

Group 1 (parallel, no dependencies):
  T-001: [title] ([work_type], [size]) - [model]
  T-002: [title] ([work_type], [size]) - [model]

Group 2 (parallel, after Group 1):
  T-003: [title] ([work_type], [size]) - [model] -> depends on T-001
  T-004: [title] ([work_type], [size]) - [model] -> depends on T-001, T-002

Does this breakdown look right?
1. Approve - write prd.json
2. Adjust - tell me what to change
3. Start Over - discard and re-scope
```

---

## prd.json Output

Write the approved plan to `prd.json` at the project root:

```json
{
  "operation": "Operation Title",
  "created": "2026-03-28T00:00:00Z",
  "updated": "2026-03-28T00:00:00Z",
  "status": "planning",
  "division": "generic",
  "priority": "standard",
  "objective": "Free-text objective",
  "success_criteria": ["criterion 1", "criterion 2"],
  "tasks": [
    {
      "id": "T-001",
      "title": "Task title",
      "description": "Detailed description of what to do",
      "work_type": "backend",
      "status": "pending",
      "dependencies": [],
      "parallel_group": 1,
      "estimated_complexity": "M",
      "recommended_model": "opus",
      "revisions": 0,
      "completed_at": null,
      "analyst_verdict": null,
      "notes": ""
    }
  ]
}
```

After writing, confirm:
```
Operation planned. [X] tasks in [Y] parallel groups written to prd.json.
Critical path: [Z] sequential steps. Estimated cost: $[min]-$[max].
Ready to conduct? (yes / not yet)
```

If yes, hand control back to the Coordinator to begin execution.
