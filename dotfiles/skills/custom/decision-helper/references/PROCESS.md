# PrOACT-URL Decision Process Structure

## Framework Overview

Based on *Smart Choices* by Hammond, Keeney, and Raiffa. The acronym stands for:

| Element | Purpose | Can short-circuit after? |
|---------|---------|--------------------------|
| **Pr**oblem | Define what you're actually deciding | Yes - problem may dissolve |
| **O**bjectives | Clarify what you want | Yes - choice may become obvious |
| **A**lternatives | Generate options | Yes - one dominant alternative |
| **C**onsequences | How alternatives meet objectives | Yes - clear winner emerges |
| **T**radeoffs | Resolve competing objectives | Yes - swaps clarify winner |
| **U**ncertainty | What you don't know | Yes - risk profile settles it |
| **R**isk Tolerance | How much risk you can bear | Yes - acceptable risk found |
| **L**inked Decisions | Future decisions this affects | Terminal |

The process is iterative and refinement-based. At any point, if the decision becomes clear,
the process terminates and moves to the Decision Record.

---

## Process Phases

### Phase 0: Intake

Capture the raw decision need before any analysis.

- **Initial decision statement** (the user's first articulation)
- **Trigger** (what prompted this decision now?)
- **Urgency / time horizon** (when must this be decided?)
- **Stakes assessment** (quick gut check: low / medium / high / critical)
- **Decision type tag** (career, financial, technical, relational, health, strategic, operational, other)

Stakes assessment determines how deep to go. A low-stakes decision may only need Problem + Objectives + a quick alternative scan. High-stakes decisions warrant the full process.

---

### Phase 1: Problem Definition (Pr)

Goal: Ensure you're solving the right problem with the right scope.

1. **Gains** - What can you gain from this situation?
2. **Trigger analysis** - Describe the connection between the trigger and the decision
3. **Constraints** - List implicit and explicit constraints. Challenge each: is it real?
4. **Essential elements** - What are the non-negotiable elements of this decision?
5. **Linked decisions** - What hinging/impinging decisions are related? (feeds Phase 7)
6. **Scope** - What is a workable scope for the problem definition?
7. **External input** - Who could help clarify the problem? Have you consulted them?
8. **Reformulated decision statement** - Restate the decision after this analysis

Output: A refined, well-bounded decision statement that replaces the initial one.

**Short-circuit check**: Has the problem dissolved or become trivially clear?

---

### Phase 2: Objectives (O)

Goal: Surface what you actually want -- both obvious and hidden objectives.

#### 2a: Explore Concerns (divergent)

Prompt widely to surface latent objectives:

1. **Best case** - What would make you really happy about this decision? Wishlist?
2. **Worst case** - What do you most want to avoid?
3. **Others' welfare** - What do you want for other people affected by this decision?
4. **Precedent** - What have others who faced similar situations thought about it?
5. **Ideal fantasy** - Consider an amazing but unfeasible outcome. What makes it great?
6. **Nightmare scenario** - Consider the worst outcome. What makes it terrible?
7. **Justification** - How would you explain/justify this decision to others?

#### 2b: Distill Objectives (convergent)

Convert the raw concerns into structured objectives:

1. **Draft objectives list** - Each as SHORT VERB + OBJECT (e.g., "save money", "reduce commute", "preserve autonomy")
2. **Five Whys per objective** - Push each objective to its fundamental level
   - Surface objective -> Why? -> Why? -> Why? -> Why? -> Why? -> Fundamental objective
3. **Fundamental objectives list** - The deep ends, not the means
4. **Means objectives list** - Retained separately; useful for generating alternatives later

Guidance:
- Objectives are personal -- don't sanitize them
- Don't limit objectives to what's easy to measure
- If the decision doesn't sit well after this phase, you've likely missed an objective

Output: A clean list of fundamental objectives and a separate list of means objectives.

**Short-circuit check**: Does one path obviously satisfy all fundamental objectives?

---

### Phase 3: Alternatives (A)

Goal: Generate a rich, varied set of alternatives. Create first, evaluate later.

#### 3a: Self-Generated Alternatives

1. **Objective-driven** - For each fundamental objective, ask "how could I achieve this?" (means objectives help here)
2. **Constraint-challenging** - What alternatives challenge your understanding of constraints?
3. **Constraint-free** - What alternatives exist if a key constraint were removed entirely?
4. **Wildly ambitious** - What would you do with unlimited resources?

#### 3b: External Alternatives

1. **Research** - How have others addressed similar situations?
2. **Consultation** - Have you asked others for suggestions? What were they?
3. **Incubation** - Have you given your unconscious time to work on it?

#### 3c: Process & Special Alternatives

1. **Process alternatives** - Would a decision process help? (coin flip, vote, arbitration, auction, scoring, delegation)
2. **Win-win alternatives** - Can you reframe to satisfy multiple parties?
3. **Information-gathering alternatives** - Would more research reduce uncertainty enough to justify the effort?
4. **Time-buying alternatives** - If waiting has significant pros, what buys you time?

#### 3d: Alternative Sufficiency Check

Before moving on, confirm:
- [ ] Have you thought hard using all the keys above?
- [ ] Would you be satisfied choosing one of these alternatives right now?
- [ ] Do you have genuine variety in the alternatives?
- [ ] Do other elements (consequences, tradeoffs) need more attention?
- [ ] Would your time be better spent on other decisions?

Output: A numbered list of all viable alternatives.

**Short-circuit check**: Is one alternative clearly dominant across all objectives?

---

### Phase 4: Consequences (C)

Goal: Understand how each alternative performs against each objective.

#### 4a: Free-Form Descriptions

1. For each alternative, write a narrative description of its consequences
2. Use concrete details: numbers, diagrams, scenarios
3. Be consistent in how you describe across alternatives
4. **Check for new objectives** that emerge from this exercise

#### 4b: King of the Hill Elimination

1. Pick the strongest-looking alternative
2. Compare each other alternative against it
3. Eliminate clearly inferior alternatives
4. Note which were cut and why

#### 4c: Consequences Table

Build a structured table:
- **Rows**: Fundamental objectives
- **Columns**: Remaining alternatives
- **Cells**: Consequence on a consistent scale per objective

Quality checks for the table:
- [ ] Common scales used across alternatives for each objective
- [ ] Precise enough (but subjective is fine if concrete)
- [ ] Recognition of objectives that resist "hard data"
- [ ] Scales relevant to you, not just what's easy to measure
- [ ] Available data fully utilized
- [ ] Expert input incorporated where appropriate

#### 4d: Pairwise Comparison

Compare remaining alternatives two at a time using pros/cons. Eliminate any that are clearly worse.

Output: A consequences table with only competitive alternatives remaining.

**Short-circuit check**: Does one alternative clearly dominate?

---

### Phase 5: Tradeoffs (T)

Goal: Resolve competing objectives when no alternative wins on everything.

#### 5a: Dominance Check

1. Build a ranking table (objectives x alternatives, ranked 1st/2nd/3rd...)
2. Identify dominated alternatives (worse on every objective) -- eliminate
3. Identify practically dominated alternatives (worse on most, barely better on rest) -- eliminate

#### 5b: Even Swaps

The core tradeoff method. Repeat until one alternative remains or the choice is clear:

1. Pick the objective easiest to equalize across alternatives
2. For each alternative pair:
   - Determine the change needed to make them equal on this objective
   - Assess what change in another objective would compensate
   - Make the swap (adjust the consequence table)
3. Once an objective is equal across all remaining alternatives, strike it out
4. Check for newly dominated alternatives -- eliminate
5. Repeat

Even swap guidance:
- Make easier swaps first
- Focus on the amount of the swap, not the importance of the objective
- Value incremental changes in context of where you started
- Be consistent across swaps

Output: A final alternative (or small set) that survives the tradeoff process.

**Short-circuit check**: Decision clear? If yes, proceed to Decision Record.

---

### Phase 6: Uncertainty (U)

Goal: Account for what you don't know.

*Note: The original form is light on this phase. This is derived from the book.*

1. **Key uncertainties** - What important things are unknown or unpredictable?
2. **Scenarios** - For each key uncertainty, what are the plausible outcomes?
3. **Likelihood assessment** - How likely is each scenario? (use qualitative if needed: very unlikely / unlikely / possible / likely / very likely)
4. **Impact on consequences** - How does each scenario change the consequences table?
5. **Risk profiles** - For each alternative, what is the range of possible outcomes?
6. **Dominance under uncertainty** - Does one alternative dominate across most/all scenarios?

Output: Risk profiles for remaining alternatives.

**Short-circuit check**: Does one alternative perform acceptably across all plausible scenarios?

---

### Phase 7: Risk Tolerance (R)

Goal: Match the decision to your appetite for risk.

1. **Risk stance** - Are you risk-averse, risk-neutral, or risk-seeking for this decision? Why?
2. **Desirability assessment** - How much do you value the best outcome vs. how much do you fear the worst?
3. **Risk mitigation** - Can you reduce the downside of a preferred alternative?
4. **Diversification** - Can you hedge by splitting across alternatives?
5. **Insurance** - Can you create a fallback or safety net?

Output: A risk-adjusted preference among remaining alternatives.

**Short-circuit check**: Is the risk-adjusted choice clear?

---

### Phase 8: Linked Decisions (L)

Goal: Consider how this decision connects to future decisions.

1. **Future decisions enabled/foreclosed** - What doors does each alternative open or close?
2. **Information value** - Will this decision reveal information that affects future choices?
3. **Reversibility** - How reversible is each alternative? What's the cost of changing course?
4. **Sequencing** - Should any part of this decision be deferred?
5. **Decision tree** - For complex linked decisions, sketch the decision tree

Output: Final adjusted preference accounting for linked decisions.

---

## Decision Record

The terminal output of the process. Every decision produces this, regardless of how deep the process went.

---

## Post-Decision Reviews

Optional but valuable for learning. Set at decision time.

### Review 1 (set date at decision time)

- **Review date**:
- **Actual outcome so far**:
- **Emotional state**:
- **Lessons learned**:
- **Where to apply lessons**:

### Review 2 / Final Review (set date at decision time)

- **Review date**:
- **Final outcome**:
- **Emotional state**:
- **Lessons learned**:
- **Where to apply lessons**:
