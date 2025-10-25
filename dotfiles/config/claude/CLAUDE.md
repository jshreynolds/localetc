# Code Quality Guidelines

## Core Principles
- **Make it work, make it right, make it fast** - in that order (Kent Beck)
- **Code is read far more often than written** - optimize for readability
- **YAGNI (You Aren't Gonna Need It)** - implement only what's needed now
- **DRY (Don't Repeat Yourself)** - but don't abstract prematurely

## Writing Clean Code
- Use **intention-revealing names** for variables, functions, and classes
- Functions should **do one thing well** (Single Responsibility Principle)
- Keep functions small - typically under 20 lines
- Extract complex conditionals into well-named variables or methods:
  ```
  // Instead of: if (!user.isActive || user.suspendedAt > Date.now())
  const userCannotAccess = !user.isActive || user.isSuspended()
  if (userCannotAccess) { ... }
  ```

## Design for Testability
- **Dependency injection** over hard-coded dependencies
- Pure functions over side effects when possible
- Design interfaces that are easy to test without mocking
- Write code that can be tested in isolation

## Refactoring & Maintenance
- **Refactor mercilessly** but in small, safe steps
- Always have tests before refactoring
- Leave code cleaner than you found it (Boy Scout Rule)
- Check for and eliminate cyclic dependencies

## Development Practices
- **Red-Green-Refactor** when appropriate:
  1. Write a failing test
  2. Make it pass with simplest code
  3. Refactor to improve design
- Use conventional commits for clear history
- Prefer composition over inheritance
- Fail fast with clear error messages

## Pragmatic Choices
- **Simple design wins** - the best code is often boring code
- Optimize for change - expect requirements to evolve
- Performance optimization only when measured and necessary
- Balance functional and object-oriented approaches based on context

## Code Smells to Avoid
- Long parameter lists
- Feature envy (methods that use another object's data excessively)
- Primitive obsession (using primitives instead of small objects)
- Shotgun surgery (one change requires edits in many places)

# Claude code configuration
When initializing a repository for use with claude code, create the following files
- `CLAUDE.md`
- `AGENT.md`
All initialization details should be written to the `AGENT.md` file and imported into `CLAUDE.md`
