# Banh Mi Ops Team Packs

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## What a Team Pack Is

A team pack is a self-contained collection of platform-specific workers, protocols, and detection rules. It teaches Banh Mi Ops how to work with a particular technology stack.

The base Banh Mi Ops framework is platform-agnostic. Division packs provide the specialization. A Drupal team pack knows about hooks, Twig templates, and Drush commands. A React team pack knows about JSX components, state management, and build tooling.

Division packs can be:

- **Bundled** -- shipped with Banh Mi Ops (Drupal, React, WordPress)
- **Community** -- created and shared by users
- **Private** -- custom packs for internal tooling or proprietary platforms

---

## File Structure Required

A team pack must follow this directory layout:

```
teams/<division-name>/
  detection.yaml        # Project type detection rules
  protocols.md          # Platform-specific coding directives
  wizard-defaults.yaml  # Default values for the Operations Wizard (optional)
  workers/
    <name>-worker.md # One or more worker definitions
  registry-entry.yaml   # Registration metadata
```

### detection.yaml

Defines how Banh Mi Ops detects that a project belongs to this division.

```yaml
division: react
markers:
  primary:
    - file: package.json
      contains: '"react"'
      location: dependencies
  secondary:
    - file_pattern: "src/**/*.tsx"
      min_count: 1
    - file_pattern: "src/**/*.jsx"
      min_count: 1
confidence_threshold: high  # requires primary + at least one secondary
```

### protocols.md

Platform-specific rules that all workers in this division must follow.

```markdown
# React Team Protocols

## Component Structure
- Functional components only. No class components.
- One component per file. File name matches component name.
- Co-locate styles: Component.module.css alongside Component.tsx.

## State Management
- Use React Context for global state unless the project uses Redux/Zustand.
- Prefer useReducer over useState for complex state.

## Testing
- Every component must have a corresponding test file.
- Use React Testing Library, not Enzyme.
```

### registry-entry.yaml

Metadata for registering the division with Banh Mi Ops.

```yaml
name: react
display_name: React
version: 1.0.0
author: Abraham Nguyen
description: Division pack for React and React-based frameworks.
workers:
  - component-worker
  - state-worker
  - routing-worker
```

---

## Worker Template

Every worker in a team pack must include these sections.

```markdown
---
name: component-worker
model: opus
division: react
version: 1.0.0
---

# Component Worker

## Specialization

Define what this worker is expert at. Be specific about the platform
features and patterns it handles.

Example: You are a React component specialist. You create, modify, and
refactor React functional components, including their associated styles,
types, and test files.

## Intake

Define what context the worker needs before starting work. This is a
checklist that the Coordinator must satisfy when delegating.

- Component name and location
- Props interface or expected data shape
- Design specifications or mockup reference
- Related components that this component interacts with
- Intelligence card for the component (if exists from a sweep)

## Execution Protocol

Step-by-step rules for how the worker works.

1. Read the intelligence card for the target component or directory.
2. Read existing component code if modifying (not creating new).
3. Implement changes following division protocols.
4. Ensure TypeScript types are complete and accurate.
5. Update or create the co-located test file.
6. Produce a debrief in the required format.

## Debrief Format

Specify the exact JSON structure the worker must output.

{
  "task_id": "",
  "files_created": [],
  "files_modified": [],
  "component_name": "",
  "props_added": [],
  "dependencies_added": [],
  "decisions": [],
  "open_questions": []
}
```

---

## Registering a Division

After creating the team pack files, register it in the global registry.

### Automatic Registration

If using `setup.sh`:

```bash
./scripts/setup.sh --install-division /path/to/your/division-pack/
```

This copies the pack into `teams/<name>/` and appends an entry to `teams/registry.yaml`.

### Manual Registration

Add an entry to `teams/registry.yaml`:

```yaml
divisions:
  - name: react
    path: teams/react/
    detection: teams/react/detection.yaml
    version: 1.0.0
  - name: your-new-division
    path: teams/your-new-division/
    detection: teams/your-new-division/detection.yaml
    version: 1.0.0
```

---

## Example: Creating a React Team

This walks through creating the React team pack from scratch.

### Step 1: Create Directory Structure

```bash
mkdir -p teams/react/workers
```

### Step 2: Write Detection Rules

```yaml
# teams/react/detection.yaml
division: react
markers:
  primary:
    - file: package.json
      contains: '"react"'
      location: dependencies
  secondary:
    - file_pattern: "src/**/*.tsx"
      min_count: 1
confidence_threshold: high
```

### Step 3: Write Protocols

```markdown
# teams/react/protocols.md

## Component Conventions
- Functional components with TypeScript.
- Named exports, not default exports.
- Props interfaces defined in the same file, exported.
```

### Step 4: Create Workers

Write `component-worker.md`, `state-worker.md`, and any other specialists needed for React projects.

### Step 5: Register

```bash
./scripts/setup.sh --install-division teams/react/
```

---

## Example: Creating a WordPress Team

### Detection Rules

```yaml
# teams/wordpress/detection.yaml
division: wordpress
markers:
  primary:
    - file: wp-config.php
      location: root
  secondary:
    - file: style.css
      contains: "Theme Name:"
      location: "wp-content/themes/*/"
confidence_threshold: medium  # primary alone is sufficient
```

### Key Workers

- **theme-worker.md** -- handles template hierarchy, template parts, functions.php
- **plugin-worker.md** -- handles plugin architecture, hooks, shortcodes
- **block-worker.md** -- handles Gutenberg block development (PHP + JS)

### Protocols

WordPress-specific rules: coding standards (WPCS), hook naming conventions, sanitization and escaping requirements, nonce verification patterns.

---

## Testing a New Division

Before distributing a team pack, verify it works correctly.

### 1. Detection Test

Navigate to a project of the target type and run:

```
/sweep --detect-only
```

Confirm the division is correctly detected. If not, adjust detection markers.

### 2. Sweep Test

Run a full sweep:

```
/sweep
```

Verify that intelligence cards are generated with platform-appropriate detail.

### 3. Operation Test

Run a small operation:

```
/banhmi
```

Create a simple task (e.g., "Add a new component" or "Create a custom block") and verify the worker follows division protocols.

### 4. Quality Chain Test

Confirm the Code Reviewer reviews changes against division protocols. If the analyst misses platform-specific issues, the protocols may need more detail.

### 5. Edge Cases

- Test with a minimal project (one module/component only)
- Test with a monorepo that contains multiple project types
- Test detection when multiple divisions could match (ensure confidence thresholds resolve correctly)

---

## Further Reading

- [ARCHITECTURE.md](ARCHITECTURE.md) -- division system design
- [CUSTOMIZATION.md](CUSTOMIZATION.md) -- extending existing divisions
- [SWEEP.md](SWEEP.md) -- how divisions affect scan profiles
