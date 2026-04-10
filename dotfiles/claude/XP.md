# Extreme Programming (XP) Principles for Software Development Agents

## Prime Directive
**Make the smallest change that delivers value.** Every modification should be atomic, testable, and reversible.

---

## Core Values

### 1. Simplicity
- Implement only what is needed *right now*
- Avoid speculative generalization
- Ask: "What is the simplest thing that could possibly work?"

### 2. Feedback
- Write a test before writing code
- Run tests after every change
- If a change breaks something, revert immediately

### 3. Communication
- Code should be self-documenting
- Name things clearly and precisely
- Leave the codebase easier to understand than you found it

### 4. Courage
- Delete dead code
- Refactor when you see a better way
- Admit when an approach isn't working

### 5. Respect
- Honor existing conventions in the codebase
- Don't break what others depend on
- Preserve backward compatibility unless explicitly changing contracts

---

## Operational Principles

### Incremental Change
```
DO:    A → A' → A'' → B
DON'T: A → B (in one leap)
```
- Break large changes into a sequence of small, working states
- Each intermediate state must compile and pass tests
- If you can't describe the change in one sentence, it's too big

### Rapid Feedback
- Write the test first (TDD)
- Run affected tests after each modification
- Integrate frequently—don't let changes accumulate

### Assume Simplicity
- Treat every problem as solvable with a simple solution
- Add complexity only when simple solutions demonstrably fail
- Prefer duplication over the wrong abstraction

### Embrace Change
- Design for change, not for permanence
- Keep coupling low so changes stay local
- Refactor continuously to maintain flexibility

---

## The Small Change Protocol

When implementing any feature or fix, follow this cycle:

```
┌─────────────────────────────────────────┐
│  1. RED    → Write one failing test     │
│  2. GREEN  → Write minimal code to pass │
│  3. REFACTOR → Clean up, tests stay green│
│  4. COMMIT → Save this working state    │
│  5. REPEAT                              │
└─────────────────────────────────────────┘
```

### Size Guidelines
| Change Type | Target Size |
|-------------|-------------|
| Single function | < 20 lines added/modified |
| Single file | < 50 lines changed |
| Multi-file change | < 5 files touched |
| Refactoring | One refactoring type at a time |

If exceeding these, decompose into smaller steps.

---

## Key Practices

### Test-Driven Development (TDD)
1. Write a test that defines expected behavior
2. Confirm the test fails
3. Write the minimum code to pass
4. Refactor while keeping tests green
5. Never write production code without a failing test

### Continuous Integration
- Integrate changes into the main branch frequently
- Every integration must pass all tests
- Fix broken builds immediately—they block everyone

### Refactoring
- Improve structure without changing behavior
- Only refactor when tests are green
- One refactoring at a time, then test
- Common refactorings: extract method, rename, inline, move

### Simple Design Rules (in priority order)
1. Passes all tests
2. Reveals intention (clear, readable)
3. No duplication (DRY)
4. Fewest elements (no unnecessary abstractions)

---

## Decision Heuristics

### When to Stop
- The test passes → stop adding code
- The code is clear → stop refactoring
- The feature works → stop adding features

### When to Split a Change
- You're changing unrelated things together
- The commit message needs "and"
- You can't easily revert one part without the other
- Tests for different behaviors are mixed

### When to Refactor vs. Rewrite
- **Refactor**: structure is awkward but behavior is correct
- **Rewrite**: behavior is wrong or requirements fundamentally changed
- Default to refactoring; rewriting loses embedded knowledge

---

## Anti-Patterns to Avoid

| Anti-Pattern | XP Alternative |
|--------------|----------------|
| Big bang integration | Continuous small integrations |
| Premature optimization | Make it work, make it right, make it fast |
| Gold plating | YAGNI (You Aren't Gonna Need It) |
| Long-lived branches | Integrate to main multiple times daily |
| Large commits | One logical change per commit |
| Testing after coding | Test-first development |
| Speculative design | Design for current requirements only |

---

## Checklist Before Every Change

- [ ] Is this the smallest useful change I can make?
- [ ] Do I have a failing test that defines success?
- [ ] Will the codebase remain in a working state?
- [ ] Can I describe this change in one sentence?
- [ ] Am I changing behavior OR structure, not both?

---

## Summary Mantras

1. **Small steps, always working**
2. **Test first, code second**
3. **Integrate early, integrate often**
4. **Simple today beats perfect tomorrow**
5. **When in doubt, make it smaller**