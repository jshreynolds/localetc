# Agent Guidelines

## Collaboration Principles (from XP)
- **Communication first** - Ask clarifying questions before making assumptions
- **Simplicity** - Do the simplest thing that works; avoid over-engineering
- **Feedback loops** - Make small changes, check in with the user, iterate
- **Courage** - Point out problems, suggest refactoring, flag technical debt
- **Collective ownership** - Treat all code as improvable; don't be precious

## Agent Behavior
- **Never add Claude as a co-author or author in commit messages**
- Make incremental changes rather than large rewrites
- Explain your reasoning when making non-obvious decisions
- When uncertain, ask - don't guess
- Respect existing code style and patterns in the codebase

## Boundaries
- Don't refactor code unrelated to the current task
- Don't add features beyond what was requested
- Stop and confirm before deleting files or making breaking changes
- If a task requires changes to more than 10 files, pause and confirm approach
- If requirements are ambiguous, ask before implementing

## Security
- Never introduce hardcoded secrets or credentials
- Validate user input at system boundaries
- Be cautious with dynamic SQL, shell commands, and eval()
- Avoid OWASP Top 10 vulnerabilities (injection, XSS, CSRF, etc.)

## Testing Expectations
- Add tests for new functionality
- Run existing tests before committing
- If tests fail after changes, fix them before continuing
- Don't skip or delete failing tests without discussion

---

# Code Quality Standards

## Core Principles
- **Make it work, make it right, make it fast** - in that order (Kent Beck)
- **Optimize for readability** - code is read far more often than written
- **YAGNI** - implement only what's needed now
- **DRY** - avoid repetition, but don't abstract prematurely

## Writing Code
- Use intention-revealing names for variables, functions, and classes
- Functions should do one thing well (Single Responsibility)
- Keep functions small - typically under 20 lines
- Extract complex conditionals into well-named variables:
  ```
  // Instead of: if (!user.isActive || user.suspendedAt > Date.now())
  const userCannotAccess = !user.isActive || user.isSuspended()
  if (userCannotAccess) { ... }
  ```

## Testability
- Use dependency injection for external services (DB, APIs, file system)
- Prefer pure functions over side effects
- Design interfaces that are easy to test without heavy mocking

## Refactoring
- Refactor in small, safe steps
- Have tests in place before refactoring
- Leave code cleaner than you found it (Boy Scout Rule)

## Development Practices
- **Red-Green-Refactor** when using TDD:
  1. Write a failing test
  2. Make it pass with simplest code
  3. Refactor to improve design
- Use conventional commits for clear history
- Prefer composition over inheritance
- Fail fast with clear error messages

## Code Smells to Flag
- Long parameter lists (>3-4 params)
- Feature envy (methods using another object's data excessively)
- Primitive obsession (using primitives instead of small value objects)
- Shotgun surgery (one change requires edits in many places)

---

# Project Setup

When initializing a repository for Claude Code:
1. Create `CLAUDE.md` in the project root
2. Create `AGENT.md` for detailed agent instructions
3. Import `AGENT.md` into `CLAUDE.md` to keep instructions organized
