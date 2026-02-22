# Banh Mi Ops Installation

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## Prerequisites

Before installing Banh Mi Ops, ensure you have the following:

- **Claude Code CLI** -- installed and authenticated. See [Anthropic's documentation](https://docs.anthropic.com/en/docs/claude-code) for setup.
- **Node.js 18+** -- required for report rendering and sweep orchestration scripts.
- **Git** -- required for cloning and updates.

Optional:

- **Playwright MCP** -- required only if you plan to use the Visual Reviewer for browser-based validation.
- **D2 CLI** -- required only if you want to render architecture diagrams from source.

---

## Option A: User-Wide Install (Global)

This installs Banh Mi Ops into your global Claude Code configuration at `~/.claude/`. It will be available across all projects.

```bash
git clone https://github.com/nguyenab/banhmi-ops.git
cd banhmi-ops
./scripts/setup.sh --global
```

The setup script copies skills, agents, templates, and scripts into `~/.claude/`. It also creates the necessary directory structure under `~/.claude/banhmi/`.

After installation, start any Claude Code session and type `/banhmi` to verify.

---

## Option B: Per-Project Install

This installs Banh Mi Ops into a single project's `.claude/` directory. Useful when you want project-specific customizations or when different projects need different Banh Mi Ops configurations.

```bash
cd /path/to/your/project
git clone https://github.com/nguyenab/banhmi-ops.git .banhmi-source
./.banhmi-source/scripts/setup.sh --local
```

The setup script copies the framework into your project's `.claude/` directory. You can then remove or keep `.banhmi-source/` as a reference.

To keep the source for easy updates:

```bash
# Keep the source and update later with:
cd .banhmi-source && git pull && ./scripts/setup.sh --local
```

---

## Option C: Multi-Project Deployment

For teams managing multiple projects, Banh Mi Ops can be installed globally with project-level overrides.

```bash
# Step 1: Global install
git clone https://github.com/nguyenab/banhmi-ops.git
cd banhmi-ops
./scripts/setup.sh --global

# Step 2: Per-project overrides
cd /path/to/project-a
mkdir -p .claude/banhmi
# Add project-specific protocols, worker overrides, etc.
```

The resolution order is:

1. Project `.claude/` (highest priority)
2. Global `~/.claude/` (fallback)

This lets you maintain a shared baseline while customizing per project.

---

## Permission Setup

Banh Mi Ops workers need file system and tool permissions to function. The setup script handles most permissions, but team-specific tools may require additional configuration.

```bash
./scripts/setup-permissions.sh --team drupal
```

The `--team` flag configures permissions specific to that platform's tooling. For example, the Drupal division may need Drush execution permissions, while the React division needs npm/yarn permissions.

Available division flags:

- `--team drupal` -- Drush, Composer, PHP permissions
- `--team generic` -- basic file system permissions only

---

## Team Pack Installation

Division packs provide platform-specific workers and protocols. Install a division alongside the base framework using the `--team` flag:

```bash
./scripts/setup.sh --global --team drupal
```

You can specify multiple divisions:

```bash
./scripts/setup.sh --global --team drupal --team generic
```

See [TEAM_PACKS.md](TEAM_PACKS.md) for creating your own.

---

## Updating

To update Banh Mi Ops:

```bash
cd /path/to/banhmi-ops
git pull origin main
./scripts/setup.sh --global   # or --local, matching your original install
```

The setup script is idempotent. It will overwrite framework files while preserving your customizations in override locations.

**What gets updated:**

- Skills (slash commands)
- Agent definitions (unless overridden at project level)
- Scripts and templates
- Division packs (base versions only)

**What is preserved:**

- Project-level overrides in `.claude/`
- Custom team packs
- Behavioral notes and recon-data data
- Event stream history

---

## Uninstalling

### Global uninstall

```bash
./scripts/setup.sh --uninstall --global
```

This removes Banh Mi Ops files from `~/.claude/` but does not touch project-level installations.

### Local project uninstall

```bash
cd /path/to/your/project
./scripts/setup.sh --uninstall --local
```

This removes Banh Mi Ops files from the project's `.claude/` directory.

### Manual cleanup

If the uninstall script is unavailable, remove these directories:

- `~/.claude/banhmi/` (global)
- `<project>/.claude/banhmi/` (project-level)
- `<project>/.claude/recon-data/` (sweep data)
- `<project>/.claude/events/` (event stream logs)

---

## Playwright MCP Setup (Optional)

The Visual Reviewer requires a browser connection via Playwright MCP to validate UI changes.

```bash
# Install Playwright
npm install -g playwright
npx playwright install chromium

# Configure the MCP server in your Claude Code settings
# Add to .claude/mcp-servers.json:
{
  "playwright": {
    "command": "npx",
    "args": ["@anthropic/playwright-mcp"]
  }
}
```

After configuration, the Visual Reviewer can launch a browser, navigate to local development URLs, take screenshots, and validate rendered output.

If Playwright MCP is not configured, the Visual Reviewer step is skipped in the quality chain, and the Coordinator will note this in the debrief.

---

## Windows-Specific Notes

Banh Mi Ops is developed and tested primarily on macOS and Linux. On Windows:

### Git Bash

Most functionality works under Git Bash. Known limitations:

- Shell scripts may need `dos2unix` conversion if cloned with CRLF line endings.
- Some path handling may require forward slashes explicitly.

```bash
# Convert line endings if needed
find ./scripts -name "*.sh" -exec dos2unix {} \;
```

### WSL (Recommended)

Windows Subsystem for Linux provides the most reliable experience:

```bash
# Inside WSL
git clone https://github.com/nguyenab/banhmi-ops.git
cd banhmi-ops
./scripts/setup.sh --global
```

Ensure Claude Code CLI is installed inside WSL, not on the Windows host, to avoid path translation issues.

### PowerShell

Not supported. Use Git Bash or WSL.

---

## Verifying Installation

After installation, verify everything is working:

```bash
# Start a Claude Code session
claude

# Test the entry point
/banhmi

# You should see the Operations Wizard prompt
```

If the `/banhmi` command is not recognized, check that the skills were correctly copied to the commands directory:

- Global: `~/.claude/commands/OPERATIONS_DIRECTOR.md` should exist
- Project: `.claude/commands/OPERATIONS_DIRECTOR.md` should exist

---

## Next Steps

- [ARCHITECTURE.md](ARCHITECTURE.md) -- understand the system design
- [CUSTOMIZATION.md](CUSTOMIZATION.md) -- configure Banh Mi Ops for your needs
- [SWEEP.md](SWEEP.md) -- run your first reconnaissance sweep
