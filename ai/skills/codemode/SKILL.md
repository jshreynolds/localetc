---
name: codemode
description: Baseline engineering principles for ANY software task — writing, editing, reviewing, refactoring, debugging, or designing code, adding a dependency, or writing tests. Load this before touching code; it should trigger very easily. Covers simplicity/YAGNI/DRY/KISS, TDD and the red-green-refactor small-change protocol, incremental commits, testability, refactoring discipline, dependency selection with a lightweight risk assessment, security guardrails, code smells, and decision heuristics. Trigger on essentially any coding, implementation, bug-fix, refactor, test-writing, or code-review request.
---

# Codemode — Engineering Principles

**Prime directive: make the smallest change that delivers value.** Every
modification should be atomic, testable, and reversible. Load and follow this
whenever you are writing, changing, reviewing, or designing code.

## Core Principles
- **Make it work, make it right, make it fast** — in that order (Kent Beck)
- **Optimize for readability** — code is read far more often than written
- **YAGNI** — implement only what is needed *right now*; avoid speculative generalization
- **DRY** — avoid repetition, but don't abstract prematurely; prefer duplication over the wrong abstraction
- **KISS** — Keep It Simple, Stupid!
- **Assume simplicity** — ask "what is the simplest thing that could possibly work?" and add complexity only when simple solutions demonstrably fail

## Writing Code
- Use intention-revealing names for variables, functions, and classes
- Functions should do one thing well (Single Responsibility)
- Keep functions small — typically under 20 lines
- Extract complex conditionals into well-named variables:
  ```
  // Instead of: if (!user.isActive || user.suspendedAt > Date.now())
  const userCannotAccess = !user.isActive || user.isSuspended()
  if (userCannotAccess) { ... }
  ```
- Prefer composition over inheritance
- Fail fast with clear error messages
- Code should be self-documenting; leave the codebase easier to understand than you found it

## Test-Driven Development
Follow the cycle:
```
┌──────────────────────────────────────────┐
│  1. RED     → Write one failing test      │
│  2. GREEN   → Write minimal code to pass  │
│  3. REFACTOR → Clean up, tests stay green │
│  4. COMMIT  → Save this working state     │
│  5. REPEAT                                │
└──────────────────────────────────────────┘
```
- Write a test that defines expected behavior, confirm it fails, then write the minimum code to pass
- Never write production code without a failing test
- Run affected tests after every change; if a change breaks something, revert immediately

## Testing Expectations
- Add tests for new functionality
- Run existing tests before committing
- If tests fail after changes, fix them before continuing
- Don't skip or delete failing tests without discussion

## The Small Change Protocol
- Incremental change: `A → A' → A'' → B`, never `A → B` in one leap
- Each intermediate state must compile and pass tests
- If you can't describe the change in one sentence, it's too big
- Integrate frequently — don't let changes accumulate; one logical change per commit
- Use conventional commits for clear history

### Size Guidelines
| Change Type | Target Size |
|-------------|-------------|
| Single function | < 20 lines added/modified |
| Single file | < 50 lines changed |
| Multi-file change | < 5 files touched |
| Refactoring | One refactoring type at a time |

If exceeding these, decompose into smaller steps.

## Testability
- Use dependency injection for external services (DB, APIs, file system)
- Prefer pure functions over side effects
- Design interfaces that are easy to test without heavy mocking

## Refactoring
- Refactor in small, safe steps; keep tests green before and after
- One refactoring at a time, then test (extract method, rename, inline, move)
- Improve structure without changing behavior — never change behavior and structure at once
- Leave code cleaner than you found it (Boy Scout Rule)
- **Refactor** when structure is awkward but behavior is correct; **rewrite** only when behavior is wrong or requirements fundamentally changed. Default to refactoring — rewriting loses embedded knowledge.

### Simple Design Rules (in priority order)
1. Passes all tests
2. Reveals intention (clear, readable)
3. No duplication (DRY)
4. Fewest elements (no unnecessary abstractions)

## Dependencies
- When adding a new package/dependency, explain **why** you chose it over alternatives (or over writing it yourself)
- Give a lightweight risk assessment covering:
  - **Maintenance** — is it actively maintained, and how recent is the last release?
  - **Popularity** — adoption signals (downloads, stars) as a proxy for community trust
  - **Footprint** — transitive dependency count and bundle/install size
  - **Licensing** — is the license compatible with this project?
  - **Security** — any known advisories, and does it need broad permissions?
- Prefer the standard library or existing dependencies before adding a new one
- Flag when a dependency is heavy relative to the problem it solves

## Security
- Never introduce hardcoded secrets or credentials
- Validate user input at system boundaries
- Be cautious with dynamic SQL, shell commands, and eval()
- Avoid OWASP Top 10 vulnerabilities (injection, XSS, CSRF, etc.)

## Code Smells to Flag
- Long parameter lists (>3-4 params)
- Feature envy (methods using another object's data excessively)
- Primitive obsession (using primitives instead of small value objects)
- Shotgun surgery (one change requires edits in many places)

## Decision Heuristics
**When to stop**
- The test passes → stop adding code
- The code is clear → stop refactoring
- The feature works → stop adding features

**When to split a change**
- You're changing unrelated things together
- The commit message needs "and"
- You can't easily revert one part without the other
- Tests for different behaviors are mixed

## Anti-Patterns to Avoid
| Anti-Pattern | Alternative |
|--------------|-------------|
| Big bang integration | Continuous small integrations |
| Premature optimization | Make it work, make it right, make it fast |
| Gold plating | YAGNI |
| Long-lived branches | Integrate to main multiple times daily |
| Large commits | One logical change per commit |
| Testing after coding | Test-first development |
| Speculative design | Design for current requirements only |

## Checklist Before Every Change
- [ ] Is this the smallest useful change I can make?
- [ ] Do I have a failing test that defines success?
- [ ] Will the codebase remain in a working state?
- [ ] Can I describe this change in one sentence?
- [ ] Am I changing behavior OR structure, not both?

## Project Setup
When initializing a repository for Claude Code:
1. Create `CLAUDE.md` in the project root
2. Create `AGENT.md` for detailed agent instructions
3. Import `AGENT.md` into `CLAUDE.md` to keep instructions organized

## Summary Mantras
1. **Small steps, always working**
2. **Test first, code second**
3. **Integrate early, integrate often**
4. **Simple today beats perfect tomorrow**
5. **When in doubt, make it smaller**
