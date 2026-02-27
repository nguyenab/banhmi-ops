# Banh Mi Ops Token Optimization

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## Tiered Model Allocation

Banh Mi Ops assigns model tiers based on task complexity, not uniformly. This is the single most impactful cost optimization in the framework.

| Tier | Model | Cost Profile | Used For |
|------|-------|-------------|----------|
| Recon | Haiku | Lowest | Sweeps, file indexing, pattern extraction, fingerprinting |
| Analysis | Sonnet | Moderate | Code review, planning assistance, analyst reviews |
| Implementation | Opus | Highest | Worker task execution, complex code generation |

The Coordinator runs on whatever model the Lead's session uses. Subagent tiers are declared in each agent's frontmatter and enforced at spawn time.

**Guideline:** Never use Opus for reconnaissance. Never use Haiku for production code generation. Match the model to the cognitive demand of the task.

---

## Sweep Cost Analysis

Sweeps use parallel Haiku agents, making them the cheapest multi-agent operation in Banh Mi Ops.

**Cost factors for a sweep:**

- Number of modules/components to scan
- Depth of each scan (file count, complexity)
- Number of parallel agents (more agents = more concurrent cost, but less wall-clock time)

**Typical costs (approximate):**

| Project Size | Full Sweep | Incremental Sweep |
|-------------|------------|-------------------|
| Small (5-10 modules) | ~5K tokens input, ~2K output per agent | 30-50% of full |
| Medium (20-30 modules) | ~15K tokens input, ~5K output per agent | 20-40% of full |
| Large (50+ modules) | ~30K tokens input, ~10K output per agent | 10-30% of full |

Incremental sweeps are cheaper because SHA-256 fingerprinting skips unchanged modules entirely. In a typical development cycle where only 2-3 modules change between sweeps, the incremental cost is minimal.

---

## Worker Token Efficiency Rules

Workers are the most expensive agents because they run on Opus and perform the most complex work. These rules keep their token consumption focused.

### 1. Targeted File Reading

Workers receive intelligence cards from the sweep. They should read only the files identified as relevant, not explore broadly.

**Expensive pattern (avoid):**
```
Read all files in web/themes/custom/mytheme/
```

**Efficient pattern (prefer):**
```
Read mytheme.theme (hooks), templates/node--article.html.twig (target template)
```

### 2. Scoped Context Windows

Workers receive only the context they need for their specific task. The Coordinator does not dump the entire operation plan into every worker; each gets its own task specification and relevant recon cards.

### 3. No Redundant Exploration

If a sweep has already documented a module's structure, the worker should not re-discover it. Intelligence cards exist precisely to eliminate this waste.

### 4. Concise Debriefs

Worker debriefs should list files changed, decisions made, and open questions. They should not narrate the execution process step by step.

---

## Analyst Token Efficiency Rules

Reviewers run on Sonnet, which is less expensive than Opus but still non-trivial at scale.

### 1. Diff-Based Review

The Code Reviewer reviews only the diff produced by workers, not the entire files. The Coordinator provides the changeset, not the full file contents.

### 2. Structured Findings

Analyst output is a structured JSON array, not prose. This keeps output tokens minimal and machine-readable.

### 3. Severity Filtering

The Report Writer filters findings by severity. Suggestions and informational notes are included in the report but do not trigger revision cycles. Only warnings and critical findings are actionable.

---

## Skip Unchanged Modules

SHA-256 fingerprinting is the backbone of incremental efficiency. The mechanism:

1. During a sweep, every scanned file gets a SHA-256 hash stored in its intelligence card.
2. On the next sweep, the file's current hash is compared against the stored hash.
3. If the hashes match, the file (and potentially the entire module) is skipped.
4. If any file in a module has changed, only that module is re-scanned.

This means a project with 30 modules where only 3 changed will re-scan approximately 10% of the codebase, saving 90% of the sweep cost.

---

## Targeted File Reading

Beyond sweeps, targeted reading applies throughout the operation lifecycle.

**Coordinator:** Reads `prd.json` and relevant recon cards. Does not read project source files directly.

**Workers:** Read only files listed in their task specification and recon cards. May read additional files if the task requires it, but should document why.

**Reviewers:** Read only the diff or changeset. The Code Reviewer may read surrounding context (a few lines above/below the change) but not entire files.

---

## Behavioral Notes vs. Full Re-Exploration

Behavioral notes (`behavioral-notes.md`) accumulate project-specific knowledge across operations. They record:

- Naming conventions discovered during previous operations
- Architectural decisions and their rationale
- Known quirks or workarounds in the codebase
- Patterns that workers should follow

Without behavioral notes, each new operation would need to rediscover these patterns, costing tokens and risking inconsistency. With them, workers start with institutional knowledge already loaded.

**Storage:** `.claude/banhmi/behavioral-notes.md`

**Growth management:** Behavioral notes are periodically summarized to prevent unbounded growth. When the file exceeds a configured threshold (default: 500 lines), the Coordinator condenses it, preserving key insights and discarding obsolete observations.

---

## Cost Tracking

Banh Mi Ops records token usage in operation debriefs and MES events. Use this data to identify optimization opportunities.

```json
{
  "token_usage": {
    "station_chief": { "input": 12000, "output": 3000 },
    "workers": {
      "theme-worker": { "input": 25000, "output": 8000 },
      "module-worker": { "input": 18000, "output": 6000 }
    },
    "reviewers": {
      "code-analyst": { "input": 8000, "output": 1500 },
      "visual-analyst": { "input": 3000, "output": 500 }
    },
    "total": { "input": 66000, "output": 19000 }
  }
}
```

Review this data after each operation. If an worker consistently uses more tokens than its peers, its task specifications may be too broad, or its recon cards may be stale.

---

## Further Reading

- [SWEEP.md](SWEEP.md) -- fingerprinting and recon details
- [ARCHITECTURE.md](ARCHITECTURE.md) -- model tier allocation
- [ITERATION.md](ITERATION.md) -- benchmarking and cost tracking
