# Banh Mi Ops Customization

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## Adding a New Worker

Workers are defined as markdown files with structured frontmatter. To create a new worker:

### 1. Create the Markdown File

Place the file in `agents/` for generic workers or `teams/<platform>/workers/` for platform-specific ones.

```markdown
---
name: api-integration-worker
model: opus
division: generic
version: 1.0.0
---

# API Integration Worker

## Specialization
You are an API integration specialist. You implement REST and GraphQL
client integrations, handle authentication flows, and write data
transformation layers.

## Intake
When assigned a task, confirm:
- Target API documentation or endpoint inventory
- Authentication method (OAuth, API key, JWT)
- Data models expected by the consuming application
- Error handling requirements

## Execution Protocol
1. Read existing API client code if present.
2. Implement the integration following project conventions.
3. Write error handling for all network and parsing failures.
4. Add inline documentation for non-obvious transformations.
5. Produce a debrief summarizing endpoints touched and decisions made.

## Debrief Format
Output a JSON object:
{
  "endpoints_integrated": [],
  "auth_method": "",
  "files_created": [],
  "files_modified": [],
  "decisions": [],
  "open_questions": []
}
```

### 2. Required Sections

Every worker file must contain these sections:

- **Frontmatter** -- `name`, `model`, `division`, `version`
- **Specialization** -- what the worker is expert at
- **Intake** -- what context the worker needs before starting
- **Execution Protocol** -- step-by-step execution rules
- **Debrief Format** -- structured output specification

### 3. Registration

Generic workers in `agents/` are auto-discovered. Division workers must be listed in their division's `registry.yaml`.

---

## Creating a Custom Team Pack

See [TEAM_PACKS.md](TEAM_PACKS.md) for the full guide. In brief:

1. Create a directory under `teams/<your-division>/`.
2. Add `detection.yaml` with project type markers.
3. Add `protocols.md` with platform-specific coding rules.
4. Add worker files under `workers/`.
5. Register in `teams/registry.yaml`.

---

## Adjusting the Operations Wizard

The Operations Wizard is the interactive planner that generates `prd.json` from Lead intent. It is defined in `skills/banhmi.md`.

To customize the wizard:

- **Change the question flow:** Edit the wizard's prompt sections to ask different planning questions.
- **Add default values:** Set team-specific defaults in `teams/<platform>/wizard-defaults.yaml`.
- **Skip steps:** Set `wizard.skip_confirmation: true` in `.claude/banhmi/config.yaml` to bypass the review step for experienced Directors.

Project-level overrides go in `.claude/commands/banhmi.md`, which takes precedence over the global version.

---

## Project-Level Overrides

Banh Mi Ops resolves files in this priority order:

1. **Project `.claude/banhmi/`** -- highest priority
2. **Global `~/.claude/banhmi/`** -- fallback

This means you can override any framework file by placing a copy at the project level.

### Common Overrides

**Custom protocols:**

```bash
# Create a project-level protocols file
cp ~/.claude/banhmi/protocols.md .claude/banhmi/protocols.md
# Edit to add project-specific rules
```

**Worker behavior:**

```bash
# Override a specific worker
mkdir -p .claude/banhmi/agents/
cp ~/.claude/banhmi/agents/theme-worker.md .claude/banhmi/agents/theme-worker.md
# Customize for this project's theming approach
```

**Configuration:**

```yaml
# .claude/banhmi/config.yaml
wizard:
  skip_confirmation: false
  default_division: drupal
sweep:
  staleness_hours: 48
  parallel_agents: 4
quality:
  skip_visual_analyst: true
  max_revision_cycles: 1
```

---

## Custom Protocols

The `protocols.md` file contains coding directives that all workers follow. It is loaded into every worker's context at spawn time.

To add project-specific rules:

```markdown
# Project Protocols

## Code Style
- Use 2-space indentation for all JavaScript/TypeScript files.
- Use 4-space indentation for PHP files.
- All functions must have JSDoc or PHPDoc comments.

## Git Conventions
- Branch names follow: feature/<task-id>-<short-description>
- Commit messages follow conventional commits format.

## Testing Requirements
- All new functions must have corresponding unit tests.
- Integration tests required for API endpoints.

## Forbidden Patterns
- No inline styles in React components.
- No direct database queries outside repository classes.
- No console.log statements in production code.
```

Protocols are additive. Project-level protocols extend (not replace) division protocols unless you explicitly set `protocols.override: true` in your config.

---

## Adding New Analyst Types

Reviewers follow the same markdown format as workers but serve a review-only purpose. They never modify project files.

### Example: Performance Analyst

```markdown
---
name: performance-analyst
model: sonnet
role: analyst
version: 1.0.0
---

# Performance Analyst

## Specialization
You review code changes for performance implications. You identify
N+1 queries, unnecessary re-renders, expensive computations in
hot paths, and missing caching opportunities.

## Intake
Receive the list of files modified during the operation and the
project's performance-sensitive areas (from recon-data).

## Analysis Protocol
1. Review each modified file for performance concerns.
2. Cross-reference with known hot paths from recon-data.
3. Flag any new database queries added inside loops.
4. Check for missing memoization in React components (if applicable).

## Findings Format
Output a JSON array of findings:
[
  {
    "file": "",
    "line": 0,
    "severity": "warning",
    "category": "performance",
    "description": "",
    "suggestion": ""
  }
]
```

Place analyst files in `agents/reviewers/` and they will be available in the quality chain. To include a custom analyst in the default chain, add it to `config.yaml`:

```yaml
quality:
  analyst_chain:
    - code-analyst
    - performance-analyst
    - visual-analyst
    - report-analyst
```

---

## Further Reading

- [ARCHITECTURE.md](ARCHITECTURE.md) -- system design context
- [TEAM_PACKS.md](TEAM_PACKS.md) -- full division creation guide
- [TOKEN_OPTIMIZATION.md](TOKEN_OPTIMIZATION.md) -- managing costs with customizations
