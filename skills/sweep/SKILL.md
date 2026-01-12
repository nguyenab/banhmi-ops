---
name: sweep
description: "Banh Mi Ops Recon Sweep. Scans project with parallel recon agents for worker pre-loading."
---

# INTELLIGENCE SWEEP

You scan a project's structure, detect its type, fingerprint key files, and produce recon cards that Workers consume before executing tasks.

---

## Project Type Detection

Scan the project root and identify the type:

| Check | Type | Key Paths |
|-------|------|-----------|
| `*.info.yml` + `modules/custom/` | Drupal | `web/modules/custom/`, `web/themes/custom/`, `config/sync/` |
| `package.json` contains `"react"` | React | `src/components/`, `src/hooks/`, `src/pages/`, `public/` |
| `wp-config.php` or `wp-content/` | WordPress | `wp-content/plugins/`, `wp-content/themes/`, `functions.php` |
| None of the above | Generic | `src/`, `lib/`, `app/`, `config/` |

Report the detected type to the Coordinator immediately.

---

## Scan Targets

For each project type, scan these areas in parallel using subagents:

### Drupal
- Custom modules: structure, routing, services, plugins
- Custom themes: templates, libraries, preprocessing
- Config sync: content types, views, field definitions
- Composer dependencies

### React
- Component tree: hierarchy, props, state management
- Routing structure
- API integration layer
- Build configuration (Vite, Webpack, Next.js, etc.)
- Package dependencies

### WordPress
- Active theme: template hierarchy, hooks, filters
- Custom plugins: structure, hooks, shortcodes
- wp-config: environment settings
- Composer or direct dependencies

### Generic
- Entry points: main files, index files, app bootstrap
- Directory structure and naming conventions
- Configuration files
- Package management (composer, npm, pip, cargo, etc.)
- Framework detection from dependencies

---

## Fingerprinting

For each scanned file, record:
- **Path** relative to project root
- **SHA-256 hash** of contents
- **Role** (config, component, route, model, controller, template, test, etc.)
- **Key exports** (function names, class names, route paths)

Fingerprints enable Workers to detect if files changed between planning and execution.

---

## Parallel Execution

Spawn one Haiku-class subagent per scan area. Each agent:
1. Reads files in its assigned area
2. Produces a structured summary
3. Returns the summary to the Sweep coordinator

Run all agents in parallel for speed.

---

## Intel Card Output

Write one YAML file per scan area to `.claude/recon-data/`:

```yaml
# .claude/recon-data/{area}.yml
area: "custom-modules"
project_type: "drupal"
scanned_at: "2026-03-28T00:00:00Z"
summary: "3 custom modules: my_module, event_manager, api_bridge"
files:
  - path: "web/modules/custom/my_module/my_module.module"
    hash: "sha256:abc123..."
    role: "module"
    exports: ["my_module_theme", "my_module_preprocess_node"]
  - path: "web/modules/custom/my_module/my_module.routing.yml"
    hash: "sha256:def456..."
    role: "routing"
    exports: ["/api/my-endpoint"]
patterns:
  - "Service injection via ContainerInjectionInterface"
  - "Event subscribers for config changes"
notes: "my_module has no tests. api_bridge uses REST resources."
```

### Directory Structure
```
.claude/
  recon-data/
    overview.yml          # Project type, root structure, key config
    {area-1}.yml          # One per scanned area
    {area-2}.yml
    ...
```

---

## Completion

After all agents return, produce a summary:

```
INTELLIGENCE SWEEP COMPLETE

Project type: [type]
Areas scanned: [count]
Files indexed: [count]
Recon cards written to: .claude/recon-data/

Key findings:
- [finding 1]
- [finding 2]
- [finding 3]
```

Hand control back to the Coordinator.
