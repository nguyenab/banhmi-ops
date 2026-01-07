# Protocols

Standing coding directives that every Banh Mi Ops worker follows. These rules are loaded at the start of each operation and applied to all generated code, regardless of division or task scope.

## Universal

- Follow existing project conventions. Match the style, naming patterns, and architecture already in the codebase.
- Never skip linting or formatting. If the project has configured linters (ESLint, PHPCodeSniffer, Prettier), run them.
- Test your changes. If the project has a test suite, run it after modifications. Write tests when adding new logic.
- Document non-obvious decisions. Add inline comments for complex logic, edge cases, or workarounds.
- Use meaningful variable and function names. Avoid abbreviations that obscure intent.
- Single responsibility principle. Each function, class, or module should do one thing well.
- No hardcoded secrets. Use environment variables or configuration files for credentials and keys.
- OWASP top 10 awareness. Sanitize inputs, escape outputs, validate data boundaries.
- Commit messages should be concise and descriptive. Reference the task ID when available.
- Prefer composition over inheritance where the language supports it.

## Drupal Projects

- Follow Drupal coding standards as documented at drupal.org/docs/develop/standards.
- Use PSR-12 for all custom PHP code.
- Target PHP 8.2+ compatibility unless the project specifies otherwise.
- Prefer dependency injection over static service calls (no `\Drupal::service()` in classes).
- Use configuration management for site settings. Never modify the database directly for config.
- Custom modules belong in `web/modules/custom/` (or `modules/custom/`).
- Respect the theme layer. Business logic stays in modules, not templates.
- Use render arrays instead of raw HTML in module code.
- Run `drush cr` after cache-affecting changes.
- Write PHPUnit tests for custom services and plugins.

## React Projects

- Follow the project's ESLint and Prettier configuration without overrides.
- Use functional components with hooks. Avoid class components in new code.
- Prefer TypeScript when the project supports it.
- Keep components focused. Extract reusable logic into custom hooks.
- Use semantic HTML elements within JSX.
- Avoid inline styles unless dynamically computed. Use CSS modules, Tailwind, or the project's chosen approach.
- Memoize expensive computations with `useMemo` and callbacks with `useCallback` where appropriate.
- Write tests with the project's testing framework (Jest, Vitest, React Testing Library).
- Prefer named exports for components and utility functions.

## WordPress Projects

- Follow WordPress coding standards (PHP, JavaScript, CSS, HTML).
- Escape all output: `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses()`.
- Sanitize all input: `sanitize_text_field()`, `absint()`, `wp_unslash()`.
- Use nonce verification for all form submissions and AJAX handlers.
- Prefix all functions, hooks, and global variables with the plugin/theme slug.
- Enqueue scripts and styles properly with `wp_enqueue_script()` / `wp_enqueue_style()`.
- Use the Settings API for option pages.
- Support translation with `__()`, `_e()`, `esc_html__()` and a proper text domain.

## Generic

- If no specific platform applies, follow the conventions already established in the repository.
- Use `.editorconfig` settings if present.
- Respect `.gitignore` patterns. Never commit build artifacts, node_modules, or IDE config.
- Write self-documenting code. If a comment is needed to explain what, the code should be refactored. Comments should explain why.
- Keep functions short. If a function exceeds 40-50 lines, consider decomposition.
- Handle errors explicitly. Avoid silent catches or empty error handlers.
