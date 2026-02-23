# Banh Mi Ops Sweep Methodology

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## What Sweeps Do

A sweep is a codebase reconnaissance operation. Before the Coordinator can plan and delegate effectively, it needs a detailed inventory of the project's structure, dependencies, patterns, and conventions.

Sweeps produce **intelligence cards**, structured YAML documents that describe individual modules, components, themes, or subsystems. These cards are consumed by workers during task execution to avoid redundant file exploration and to ensure changes align with existing patterns.

Sweeps matter because:

1. **They prevent blind exploration.** Without sweep data, each worker would need to independently scan the codebase, wasting tokens and time.
2. **They detect change.** SHA-256 fingerprinting identifies which modules have changed since the last sweep, allowing the system to skip unchanged areas.
3. **They inform planning.** The Operations Wizard uses sweep data to generate more accurate task decompositions and worker assignments.

---

## SHA-256 Fingerprinting

Every file scanned during a sweep is fingerprinted using SHA-256. The hash is stored in the intelligence card alongside the file path and scan timestamp.

```yaml
# Example fingerprint entry
files:
  - path: src/components/Header/Header.tsx
    sha256: a3f2b8c9d1e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9
    scanned_at: 2026-03-28T14:00:00Z
  - path: src/components/Header/Header.module.css
    sha256: b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4
    scanned_at: 2026-03-28T14:00:00Z
```

On subsequent sweeps, Banh Mi Ops compares the current file hash against the stored hash. If they match, the module is skipped entirely. This is the primary mechanism for cost optimization in large codebases.

---

## Parallel Recon Agent Deployment

Sweeps deploy multiple lightweight recon agents in parallel. Each agent scans a subset of the project using the Haiku model tier (fast, inexpensive, sufficient for pattern extraction).

```
Coordinator
  ├─► Recon Agent 1 (modules A-D)
  ├─► Recon Agent 2 (modules E-H)
  ├─► Recon Agent 3 (themes)
  └─► Recon Agent 4 (shared libraries)
```

The number of parallel agents is configurable:

```yaml
# .claude/banhmi/config.yaml
sweep:
  parallel_agents: 4
  model: haiku
```

Each recon agent produces one or more intelligence cards and returns them to the Coordinator, which writes them to the `recon-data/` directory.

---

## Project Type Detection

Before scanning, Banh Mi Ops identifies the project type by checking for known markers in the filesystem.

### Detection Rules

| Project Type | Primary Markers | Secondary Markers |
|-------------|-----------------|-------------------|
| Drupal | `*.info.yml` in modules/ or themes/ | `composer.json` with `drupal/core` dependency |
| React | `package.json` with `react` dependency | `src/` directory with `.tsx` or `.jsx` files |
| WordPress | `wp-config.php` | `style.css` with `Theme Name:` header |
| Generic | None of the above | Falls back to language detection via file extensions |

Detection results are stored in `.claude/banhmi/detected-type.yaml`:

```yaml
project_type: drupal
confidence: high
markers_found:
  - path: web/modules/custom/mymodule/mymodule.info.yml
    type: info_yml
  - path: composer.json
    type: composer_drupal_core
detected_at: 2026-03-28T14:00:00Z
```

---

## Scan Profiles by Project Type

Each project type has a tailored scan profile that determines what to look for and where.

### Drupal Scan Profile

- Custom modules (`web/modules/custom/`)
- Custom themes (`web/themes/custom/`)
- Configuration (`config/sync/`)
- Composer dependencies (top-level `composer.json`)
- Service definitions (`*.services.yml`)
- Routing (`*.routing.yml`)
- Hook implementations (`*.module` files)

### React Scan Profile

- Components (`src/components/`)
- Pages or routes (`src/pages/`, `src/routes/`)
- State management (`src/store/`, `src/context/`)
- API layer (`src/api/`, `src/services/`)
- Configuration (`package.json`, `tsconfig.json`, `vite.config.*`)
- Test files (`**/*.test.*`, `**/*.spec.*`)

### WordPress Scan Profile

- Theme files (`wp-content/themes/<active-theme>/`)
- Plugin files (`wp-content/plugins/`)
- Configuration (`wp-config.php`)
- Template hierarchy (`template-parts/`, `page-*.php`)

### Generic Scan Profile

- Source directories (`src/`, `lib/`, `app/`)
- Configuration files at project root
- Test directories
- Build configuration

---

## Output Format: Intelligence Cards

Intelligence cards are YAML documents that describe a single module, component, or subsystem.

```yaml
# .claude/recon-data/modules/mymodule.yaml
name: mymodule
type: drupal_module
path: web/modules/custom/mymodule
description: Handles custom content import from external feeds.
scanned_at: 2026-03-28T14:05:00Z

structure:
  entry_point: mymodule.module
  services: mymodule.services.yml
  routing: mymodule.routing.yml
  config:
    - config/install/mymodule.settings.yml

files:
  - path: mymodule.module
    sha256: abc123...
    purpose: Hook implementations and preprocess functions
  - path: src/Service/ImportService.php
    sha256: def456...
    purpose: Main import logic, handles feed parsing

dependencies:
  - drupal:node
  - drupal:taxonomy
  - guzzlehttp/guzzle

patterns_observed:
  - Uses dependency injection via services.yml
  - Implements hook_cron for scheduled imports
  - Custom Drush command in src/Commands/

notes: >
  The ImportService uses a custom queue system rather than
  Drupal's built-in Queue API. Workers modifying import
  logic should maintain this pattern.
```

---

## Site-Intel Directory Structure

```
.claude/recon-data/
  detected-type.yaml
  project-overview.yaml
  modules/
    mymodule.yaml
    another_module.yaml
  themes/
    mytheme.yaml
  components/
    Header.yaml
    Footer.yaml
  config/
    settings-inventory.yaml
  last-sweep.yaml
```

The `last-sweep.yaml` file records metadata about the most recent sweep:

```yaml
started_at: 2026-03-28T14:00:00Z
completed_at: 2026-03-28T14:08:32Z
modules_scanned: 12
modules_skipped: 5
cards_updated: 7
recon_agents_used: 4
model: haiku
```

---

## Freshness and Staleness

Intelligence cards have a configurable staleness threshold. By default, cards older than 72 hours are considered stale and will be refreshed on the next sweep.

```yaml
# .claude/banhmi/config.yaml
sweep:
  staleness_hours: 72
```

Staleness is checked at two points:

1. **Before an operation.** The Coordinator checks whether sweep data is fresh enough to plan from. If stale, it prompts the Lead to run a sweep first.
2. **During a sweep.** Each module's card is checked against its staleness threshold. Fresh cards with unchanged SHA-256 hashes are skipped entirely.

---

## Cost Optimization

Sweeps are designed to minimize token consumption:

1. **SHA-256 skip logic.** Unchanged modules are not re-scanned.
2. **Haiku model tier.** Recon agents use the cheapest model sufficient for pattern extraction.
3. **Parallel execution.** Multiple agents scan simultaneously, reducing wall-clock time.
4. **Targeted paths.** Scan profiles limit which directories are examined, avoiding node_modules/, vendor/, and other dependency directories.
5. **Incremental updates.** Only the changed portions of an intelligence card are regenerated.

For a typical medium-sized project (20-30 modules), a full sweep costs approximately the same as a single worker task. Incremental sweeps (where most modules are unchanged) cost a fraction of that.

---

## Further Reading

- [ARCHITECTURE.md](ARCHITECTURE.md) -- how sweeps fit into the system
- [TOKEN_OPTIMIZATION.md](TOKEN_OPTIMIZATION.md) -- broader cost strategies
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) -- fixing sweep issues
