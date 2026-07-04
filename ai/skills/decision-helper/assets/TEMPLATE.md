# Decision Log: {{DECISION_TITLE}}

## Metadata

| Field | Value |
|-------|-------|
| **ID** | `{{YYYYMMDD-HHMMSS-slug}}` |
| **Status** | `in-progress` \| `decided` \| `abandoned` \| `deferred` |
| **Started** | {{ISO 8601 datetime}} |
| **Decided** | {{ISO 8601 datetime or blank}} |
| **Decision type** | {{career / financial / technical / relational / health / strategic / operational / other}} |
| **Stakes** | {{low / medium / high / critical}} |
| **Process depth** | {{phase name where process terminated, e.g., "Tradeoffs"}} |
| **Tags** | {{freeform tags for future retrieval}} |

---

## Phase 0: Intake

### Initial Decision Statement
{{verbatim first articulation from user}}

### Trigger
{{what prompted this decision now}}

### Urgency / Time Horizon
{{when must this be decided}}

### Stakes Rationale
{{why this stakes level}}

---

## Phase 1: Problem Definition

### Gains
{{what can be gained from this situation}}

### Trigger Analysis
{{connection between the trigger and the decision}}

### Constraints
| # | Constraint | Type | Real? | Notes |
|---|-----------|------|-------|-------|
| 1 | {{constraint}} | implicit/explicit | yes/no/uncertain | {{notes}} |

### Essential Elements
{{non-negotiable elements}}

### Related Decisions
| Decision | Relationship | Status |
|----------|-------------|--------|
| {{decision}} | hinging/impinging/enabling | {{known/unknown}} |

### Scope
{{workable scope for the problem}}

### External Input
| Person/Source | Consulted? | Input |
|--------------|-----------|-------|
| {{who}} | yes/no/pending | {{what they said}} |

### Reformulated Decision Statement
{{refined decision statement after analysis}}

---

## Phase 2: Objectives

### Concerns Explored

| # | Prompt | Response |
|---|--------|----------|
| 1 | Best case / wishlist | {{response}} |
| 2 | Worst case / what to avoid | {{response}} |
| 3 | Impact on others | {{response}} |
| 4 | Precedent from others | {{response}} |
| 5 | Ideal fantasy (and why) | {{response}} |
| 6 | Nightmare scenario (and why) | {{response}} |
| 7 | How you'd justify it | {{response}} |

### Objectives

| # | Draft Objective | Five Whys Chain | Fundamental Objective | Type |
|---|----------------|-----------------|----------------------|------|
| 1 | {{verb + object}} | {{chain}} | {{fundamental}} | fundamental/means |

### Fundamental Objectives (final)
1. {{objective}}

### Means Objectives (retained for alternative generation)
1. {{objective}}

---

## Phase 3: Alternatives

### Self-Generated
| # | Alternative | Source Method | Description |
|---|------------|--------------|-------------|
| 1 | {{name}} | objective-driven / constraint-challenging / constraint-free / ambitious | {{brief description}} |

### Externally Sourced
| # | Alternative | Source | Description |
|---|------------|--------|-------------|
| 1 | {{name}} | research / consultation / incubation | {{brief description}} |

### Process & Special Alternatives
| # | Alternative | Type | Description |
|---|------------|------|-------------|
| 1 | {{name}} | process / win-win / info-gathering / time-buying | {{brief description}} |

### Sufficiency Check
- [ ] Thought hard using all generation methods
- [ ] Would be satisfied choosing one of these now
- [ ] Genuine variety in alternatives
- [ ] Ready to evaluate consequences
- [ ] Time well spent vs. other decisions

### All Alternatives (consolidated, numbered)
1. {{alternative}}

---

## Phase 4: Consequences

### Free-Form Descriptions
#### Alternative 1: {{name}}
{{narrative description with concrete details}}

#### Alternative 2: {{name}}
{{narrative description with concrete details}}

### New Objectives Discovered
{{any objectives that emerged during consequence analysis, or "None"}}

### Elimination Round: King of the Hill
| Alternative | vs. Strongest | Verdict | Rationale |
|------------|--------------|---------|-----------|
| {{name}} | {{strongest}} | keep/cut | {{why}} |

### Consequences Table
| Objective | Alt 1: {{name}} | Alt 2: {{name}} | Alt 3: {{name}} | Scale |
|-----------|----------------|----------------|----------------|-------|
| {{obj 1}} | {{value}} | {{value}} | {{value}} | {{unit/scale}} |

### Quality Checks
- [ ] Common scales across alternatives per objective
- [ ] Sufficient precision
- [ ] Subjective objectives given due weight
- [ ] Scales relevant to decision-maker
- [ ] Available data utilized
- [ ] Expert input where appropriate

### Pairwise Eliminations
| Comparison | Pros | Cons | Verdict |
|-----------|------|------|---------|
| {{A vs B}} | {{pros of A over B}} | {{cons of A vs B}} | keep {{winner}} |

### Surviving Alternatives
1. {{alternative}}

---

## Phase 5: Tradeoffs

### Ranking Table
| Objective | Alt 1: {{name}} | Alt 2: {{name}} | Alt 3: {{name}} |
|-----------|----------------|----------------|----------------|
| {{obj}} | {{rank}} | {{rank}} | {{rank}} |

### Dominated Alternatives Eliminated
| Alternative | Dominated by | Type |
|------------|-------------|------|
| {{name}} | {{name}} | dominated / practically dominated |

### Even Swaps
| Swap # | Objective Equalized | Alternative Adjusted | Change Made | Compensating Change | Objective Struck? |
|--------|--------------------|--------------------|-------------|--------------------|--------------------|
| 1 | {{objective}} | {{alt}} | {{change}} | {{compensation}} | yes/no |

### Post-Tradeoff Survivors
1. {{alternative}}

---

## Phase 6: Uncertainty

### Key Uncertainties
| # | Uncertainty | Impact Level | Affects Alternatives |
|---|-----------|-------------|---------------------|
| 1 | {{uncertainty}} | high/medium/low | {{which alternatives}} |

### Scenarios
| Uncertainty | Scenario | Likelihood | Impact on Consequences |
|------------|----------|-----------|----------------------|
| {{uncertainty}} | {{scenario}} | very unlikely / unlikely / possible / likely / very likely | {{impact}} |

### Risk Profiles
| Alternative | Best Case | Most Likely | Worst Case |
|------------|----------|-------------|-----------|
| {{name}} | {{outcome}} | {{outcome}} | {{outcome}} |

### Dominance Under Uncertainty
{{analysis of which alternatives perform well across scenarios}}

---

## Phase 7: Risk Tolerance

### Risk Stance
{{risk-averse / risk-neutral / risk-seeking, and why}}

### Desirability Assessment
{{how much you value best outcome vs. fear worst}}

### Risk Mitigation Options
| Alternative | Mitigation | Feasibility |
|------------|-----------|-------------|
| {{name}} | {{mitigation}} | {{feasible/impractical}} |

### Risk-Adjusted Preference
{{which alternative best fits your risk tolerance}}

---

## Phase 8: Linked Decisions

### Future Decisions
| Decision | Opened by | Closed by | Importance |
|----------|----------|----------|-----------|
| {{decision}} | {{which alts}} | {{which alts}} | high/medium/low |

### Reversibility
| Alternative | Reversibility | Cost to Reverse |
|------------|--------------|----------------|
| {{name}} | high/medium/low/irreversible | {{cost}} |

### Sequencing Considerations
{{should any part be deferred?}}

### Final Adjusted Preference
{{accounting for linked decisions}}

---

## Decision Record

> This section is the canonical, stable output. Everything above is process; this is the result.

### Decision Statement
{{the refined decision question}}

### Decision
{{the chosen alternative, stated clearly}}

### Key Objectives Served
1. {{fundamental objective}} -- {{how the decision serves it}}

### Key Tradeoffs Accepted
1. {{what was given up}} in exchange for {{what was gained}}

### Key Risks Accepted
1. {{risk}} -- mitigated by {{mitigation, or "accepted"}}

### Conditions for Revisiting
{{what would need to change for this decision to be reconsidered}}

### Decided
{{ISO 8601 datetime}}

### Emotional State at Decision
{{how you feel about the decision right now}}

### Expected Outcome
{{what you expect to happen}}

---

## Reviews

### Review 1

| Field | Value |
|-------|-------|
| **Scheduled** | {{ISO 8601 date}} |
| **Completed** | {{ISO 8601 date or blank}} |

- **Actual outcome so far**:
- **Emotional state**:
- **Lessons learned**:
- **Where to apply lessons**:

### Final Review

| Field | Value |
|-------|-------|
| **Scheduled** | {{ISO 8601 date}} |
| **Completed** | {{ISO 8601 date or blank}} |

- **Final outcome**:
- **Emotional state**:
- **Lessons learned**:
- **Where to apply lessons**:
