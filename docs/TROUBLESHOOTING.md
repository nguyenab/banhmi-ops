# Banh Mi Ops Troubleshooting

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## "Claude keeps asking for permission"

**Symptom:** Every worker spawn or file operation triggers a permission prompt, interrupting the workflow.

**Cause:** MCP tool permissions have not been configured for the active division.

**Fix:**

```bash
./scripts/setup-permissions.sh --team <your-division>
```

Replace `<your-division>` with `drupal` or `generic`. This script registers the required tool permissions so workers can read and write files, execute build commands, and use team-specific tools without repeated prompts.

If you have already run the script and still see prompts, check that your Claude Code session was restarted after permission setup. Permission changes require a fresh session.

---

## "Worker can't find project files"

**Symptom:** An worker reports that it cannot locate expected files (e.g., theme files, component directories, configuration).

**Cause:** The worker's working directory or project root detection is incorrect.

**Fix:**

1. Verify the project root is correctly detected. Banh Mi Ops looks for markers like `.git/`, `package.json`, `composer.json`, or `.info.yml` to determine the project root.
2. Check that you launched Claude Code from the project root directory.
3. If your project has an unusual structure, set the root explicitly in `.claude/banhmi/config.yaml`:

```yaml
project:
  root: /absolute/path/to/project
```

4. For Drupal projects specifically, ensure the `.info.yml` file is present and that the worker's division detection found the correct docroot path.

---

## "Sweep produces empty results"

**Symptom:** Running `/sweep` completes but the intelligence cards in `.claude/recon-data/` are empty or missing.

**Cause:** The scan paths do not match the actual project structure, or project type detection failed.

**Fix:**

1. Verify project type detection by checking `.claude/banhmi/detected-type.yaml`. If this file is missing or shows `generic` for a specialized project, ensure the correct markers exist:
   - **Drupal:** `*.info.yml` in expected locations
   - **React:** `package.json` with `react` in dependencies
   - **WordPress:** `wp-config.php` or `style.css` with WordPress theme header

2. Check scan paths. If your project's structure deviates from conventions, add custom scan paths:

```yaml
# .claude/banhmi/config.yaml
sweep:
  additional_paths:
    - src/custom-modules/
    - web/themes/custom/
```

3. Run the sweep in verbose mode for diagnostic output:

```
/sweep --verbose
```

---

## "Visual Reviewer can't connect to browser"

**Symptom:** The Visual Reviewer reports a connection failure or is skipped with a "no browser available" message.

**Cause:** Playwright MCP is not installed or not configured.

**Fix:**

1. Install Playwright:

```bash
npm install -g playwright
npx playwright install chromium
```

2. Configure the MCP server in `.claude/mcp-servers.json`:

```json
{
  "playwright": {
    "command": "npx",
    "args": ["@anthropic/playwright-mcp"]
  }
}
```

3. Restart your Claude Code session.

4. Ensure your local development server is running. The Visual Reviewer needs a URL to navigate to. Set the URL in your config:

```yaml
# .claude/banhmi/config.yaml
visual:
  base_url: http://localhost:3000
```

If you do not need visual validation, you can disable it:

```yaml
quality:
  skip_visual_analyst: true
```

---

## "prd.json not found when resuming"

**Symptom:** After starting an operation and resuming in a new session, the Coordinator cannot find the operation plan.

**Cause:** The `prd.json` file location does not match what the Coordinator expects.

**Fix:**

Banh Mi Ops stores operation plans in `.claude/banhmi/operations/`. Each operation gets a timestamped directory:

```
.claude/banhmi/operations/
  2026-03-28T14-30-00/
    prd.json
    debrief.json
    events.ndjson
```

To resume a specific operation:

```
/banhmi --resume .claude/banhmi/operations/2026-03-28T14-30-00/prd.json
```

If the file was moved or the path changed, provide the absolute path. To avoid this issue, do not move operation files between sessions.

---

## "Division not detected"

**Symptom:** The Coordinator defaults to the `generic` division even though the project is clearly a Drupal project.

**Cause:** Project type markers are missing or in unexpected locations.

**Fix:**

1. Check what Banh Mi Ops detected:

```
/sweep --detect-only
```

2. If detection fails, verify the markers each division looks for:
   - **Drupal:** `*.info.yml` files under a `modules/` or `themes/` directory

3. As a fallback, set the division manually:

```yaml
# .claude/banhmi/config.yaml
project:
  division: drupal
```

---

## "Report renderer fails"

**Symptom:** The debrief report generation throws an error or produces empty output.

**Cause:** Node.js dependencies for the report renderer are not installed.

**Fix:**

```bash
cd /path/to/banhmi-ops/scripts
npm install
```

If the error persists, check:

1. Node.js version is 18 or higher: `node --version`
2. The debrief JSON is valid: `cat .claude/banhmi/operations/<timestamp>/debrief.json | python3 -m json.tool`
3. The template file exists: `ls templates/operation-debrief.html`

If the debrief JSON is malformed (usually due to an worker crashing mid-operation), you can regenerate it:

```
/debrief --regenerate
```

---

## General Debugging Tips

- **Check event logs.** The Banh Mi Event Stream in `.claude/events/` records all worker lifecycle events. Use these to trace where an operation went wrong.
- **Increase verbosity.** Most skills accept a `--verbose` flag that produces detailed diagnostic output.
- **Isolate the issue.** Run a single worker manually with `/banhmi --task <task-id> --worker <name>` to test one step at a time.
- **Clear stale intel.** If sweeps seem outdated, delete `.claude/recon-data/` and re-run `/sweep` to regenerate all intelligence cards from scratch.

---

## Getting Help

File issues at [github.com/nguyenab/banhmi-ops/issues](https://github.com/nguyenab/banhmi-ops/issues) with:

- Your Banh Mi Ops version (`cat ~/.claude/banhmi/version.txt`)
- The error message or unexpected behavior
- Your project type and division
- Relevant entries from `.claude/events/`
