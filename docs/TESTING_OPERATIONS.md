# Banh Mi Ops Testing Operations

**Author:** Abraham Nguyen
**Repository:** nguyenab/banhmi-ops

---

## Testing Wizard Workflow

Testing operations follow the same wizard-driven workflow as implementation operations, with a test-specific planning phase.

### 1. Initiate

```
/banhmi --test
```

The `--test` flag tells the Operations Wizard to enter testing mode. Instead of decomposing a feature into implementation tasks, it decomposes a testing scope into test plan tasks.

### 2. Scope Definition

The wizard asks the Lead to define:

- **Test target:** which module, component, or feature to test
- **Test types:** unit, integration, end-to-end, or a combination
- **Coverage goals:** specific functions, critical paths, or broad coverage
- **Existing tests:** whether there are tests to extend or if starting fresh

### 3. Plan Generation

The wizard produces a `prd.json` with test-specific task definitions:

```json
{
  "operation_type": "testing",
  "target": "web/modules/custom/mymodule",
  "tasks": [
    {
      "id": "test-001",
      "type": "unit-test",
      "target": "src/Service/ImportService.php",
      "description": "Unit tests for ImportService feed parsing methods",
      "framework": "phpunit"
    },
    {
      "id": "test-002",
      "type": "integration-test",
      "target": "src/Controller/ImportController.php",
      "description": "Integration tests for import API endpoint",
      "framework": "phpunit"
    }
  ]
}
```

### 4. Execution

The Coordinator delegates each test task to a testing worker, which writes test files, runs them, and reports results.

---

## Test Types by Platform

Each division defines its supported test frameworks and conventions.

### Drupal

| Test Type | Framework | Location Convention |
|-----------|-----------|-------------------|
| Unit | PHPUnit | `tests/src/Unit/` |
| Kernel | PHPUnit (Kernel) | `tests/src/Kernel/` |
| Functional | PHPUnit (Functional) | `tests/src/Functional/` |
| FunctionalJS | PHPUnit + WebDriver | `tests/src/FunctionalJavascript/` |

### React

| Test Type | Framework | Location Convention |
|-----------|-----------|-------------------|
| Unit | Jest or Vitest | `__tests__/` or `*.test.tsx` alongside component |
| Integration | Jest or Vitest | `__tests__/integration/` |
| E2E | Playwright or Cypress | `e2e/` or `cypress/` |

### WordPress

| Test Type | Framework | Location Convention |
|-----------|-----------|-------------------|
| Unit | PHPUnit | `tests/unit/` |
| Integration | PHPUnit (WP integration) | `tests/integration/` |
| E2E | Playwright or Cypress | `tests/e2e/` |

### Python

| Test Type | Framework | Location Convention |
|-----------|-----------|-------------------|
| Unit | pytest | `tests/` or `test_*.py` alongside source |
| Integration | pytest | `tests/integration/` |
| E2E | pytest + Selenium/Playwright | `tests/e2e/` |

---

## Testing Worker Deployment

Testing workers are specialized agents that understand test framework conventions, assertion patterns, and mocking strategies for their platform.

### Worker Capabilities

- Read the target source code and its intelligence card
- Identify testable functions, methods, and behaviors
- Generate test files following project conventions
- Run the test suite and capture results
- Fix failing tests within the same session (up to 2 attempts)

### Context Provided

Each testing worker receives:

- The task specification from `prd.json`
- The intelligence card for the target module
- Existing test files (if any) for pattern matching
- Project-level testing protocols from `protocols.md`

### Constraints

- Testing workers do not modify production code.
- If a test reveals a bug in production code, the worker documents it in the debrief rather than fixing it.
- Test data and fixtures are created within the test directory, not in the project's source tree.

---

## Test Plan Format

Test plans are embedded in the `prd.json` task definitions. Each test task includes:

```json
{
  "id": "test-003",
  "type": "unit-test",
  "target": "src/components/Header/Header.tsx",
  "framework": "vitest",
  "description": "Test Header component rendering, navigation state, and responsive behavior",
  "assertions": [
    "Renders without crashing",
    "Displays navigation links matching route config",
    "Applies active class to current route link",
    "Collapses to mobile menu below 768px breakpoint"
  ],
  "mocking_requirements": [
    "Mock useRouter hook",
    "Mock window.matchMedia for responsive tests"
  ]
}
```

The `assertions` field guides the worker on what to verify. The `mocking_requirements` field identifies dependencies that need to be stubbed or mocked.

---

## Results Reporting

After all testing workers complete, the Coordinator compiles a test results summary.

### Individual Worker Debrief

```json
{
  "task_id": "test-001",
  "test_file": "tests/src/Unit/Service/ImportServiceTest.php",
  "tests_written": 8,
  "tests_passed": 7,
  "tests_failed": 1,
  "failure_details": [
    {
      "test": "testParseFeedWithMalformedXml",
      "reason": "Expected InvalidArgumentException but received RuntimeException",
      "note": "Production code may have incorrect exception type. Documented for review."
    }
  ],
  "coverage_notes": "Covers all public methods of ImportService. Private method _normalizeDate not directly tested but exercised through testParseFeedWithDates."
}
```

### Operation-Level Summary

The Report Writer aggregates all test debriefs into a unified report:

- Total tests written across all tasks
- Pass/fail ratio
- Bugs discovered (documented, not fixed)
- Coverage gaps identified
- Recommendations for additional testing

---

## Further Reading

- [ARCHITECTURE.md](ARCHITECTURE.md) -- how testing fits into the operation model
- [CUSTOMIZATION.md](CUSTOMIZATION.md) -- adding custom test frameworks
- [TOKEN_OPTIMIZATION.md](TOKEN_OPTIMIZATION.md) -- managing testing operation costs
