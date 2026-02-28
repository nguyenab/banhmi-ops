# Banh Mi Ops Iteration and Benchmarking

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## Framework Iteration Checklist

When making changes to the Banh Mi Ops framework itself (updating agent definitions, modifying protocols, changing model tiers), follow this checklist to ensure changes produce measurable improvements.

### Before Making Changes

1. **Select a benchmark operation.** Choose a representative operation that you have run before and can run again. Ideally, pick one with known cost and quality data from a previous debrief.
2. **Record the baseline.** Save the current debrief JSON, MES event log, and any Director observations about quality, speed, and cost.
3. **Document the hypothesis.** Write down what you expect the change to improve and why. For example: "Switching the Code Reviewer from Opus to Sonnet should reduce analyst costs by 40% without degrading finding quality."

### Making Changes

4. **Change one variable at a time.** Do not simultaneously change model tiers, agent prompts, and sweep settings. Isolate the variable so you can attribute any improvement or regression to the specific change.
5. **Version the change.** Increment the version in the modified agent's frontmatter or in `config.yaml` so you can trace which version produced which results.

### After Making Changes

6. **Run the benchmark operation.** Execute the same operation as the baseline, against the same codebase state (use a Git branch or tag to ensure consistency).
7. **Compare debriefs.** Use the cost tracking and quality metrics to compare before and after.
8. **Decide: keep, revert, or refine.** If the change improved the target metric without regressing others, keep it. Otherwise, revert or iterate further.

---

## How to Measure Improvement

Banh Mi Ops tracks several metrics that serve as improvement indicators.

### Cost Metrics

- **Total token usage** (input + output, broken down by agent)
- **Cost per task** (tokens used by the worker assigned to each task)
- **Sweep cost** (full vs. incremental)
- **Analyst overhead** (tokens used by the quality chain relative to implementation)

### Quality Metrics

- **Analyst findings count** by severity (critical, warning, suggestion)
- **Revision cycles triggered** (0 = clean first pass, 1 = minor issues, 2 = significant issues)
- **Director satisfaction** (manual rating, recorded in the debrief)

### Speed Metrics

- **Wall-clock time** from operation start to completion
- **Per-task duration** from worker spawn to debrief
- **Analyst chain duration** from first analyst to report completion

---

## Cost Tracking Across Operations

Every operation debrief includes a `token_usage` section. To track costs over time, aggregate these across operations.

### Manual Tracking

Extract token data from debriefs:

```bash
# List all operation debriefs
ls .claude/banhmi/operations/*/debrief.json

# Extract token totals
for f in .claude/banhmi/operations/*/debrief.json; do
  echo "$(dirname $f | xargs basename): $(jq '.token_usage.total' $f)"
done
```

### Trend Analysis

Compare costs across similar operations to identify trends:

| Operation Date | Type | Tasks | Total Tokens | Revisions | Findings |
|---------------|------|-------|-------------|-----------|----------|
| 2026-03-20 | Feature | 4 | 85K | 1 | 5 |
| 2026-03-24 | Feature | 3 | 62K | 0 | 2 |
| 2026-03-28 | Feature | 5 | 78K | 1 | 3 |

If costs are rising without a corresponding increase in task count or complexity, investigate which agents are consuming more tokens and why.

---

## Before/After Comparison Methodology

When evaluating a framework change, structure the comparison as follows.

### 1. Fix the Codebase State

Check out the same Git commit for both the before and after runs. If the codebase changed between runs, you cannot attribute differences to the framework change.

```bash
git checkout <benchmark-commit>
```

### 2. Run the Baseline

Execute the benchmark operation with the previous framework version. Save the debrief.

### 3. Apply the Framework Change

Update the framework files (agent definition, config, protocol, etc.).

### 4. Run the Comparison

Execute the same operation with the updated framework. Save the debrief.

### 5. Diff the Results

Compare the two debriefs side by side:

```bash
diff <(jq . baseline-debrief.json) <(jq . comparison-debrief.json)
```

Focus on:

- **Token usage delta:** Did the change reduce or increase cost?
- **Quality delta:** Did findings increase (regression) or decrease (improvement)?
- **Revision delta:** Were fewer or more revision cycles needed?
- **Time delta:** Was the operation faster or slower?

### 6. Document the Outcome

Record the comparison in a changelog or iteration log so future changes can build on this data rather than repeating experiments.

---

## Further Reading

- [TOKEN_OPTIMIZATION.md](TOKEN_OPTIMIZATION.md) -- cost reduction strategies
- [EVENT_STREAM.md](EVENT_STREAM.md) -- event data for analysis
- [ARCHITECTURE.md](ARCHITECTURE.md) -- understanding what to iterate on
