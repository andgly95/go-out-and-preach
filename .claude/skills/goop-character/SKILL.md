---
name: goop-character
description: Use this skill when adding any new character to the Go Out and Preach game — householder archetypes (Polite Refuser, Hostile Slammer, Curious Seeker, Lonely Elderly, Disillusioned Catholic, Hostile Christian, Apostate, Householder of Note) or named NPCs (the Parent in the Truth, Coordinator of Elders, Strict Elder, Sister Pioneer, Service Partner, Sister Who Talks, Grandparent, Sibling Drifting, Worldly Coworker). Trigger whenever the user mentions M4.1+ archetype expansion, adding a householder, populating territory houses with variety, writing dialogue for a new character, or any reference to cast.md or dialogue-context.md content additions. Trigger even if the user does not explicitly say "skill" or "character" — phrases like "add the Apostate," "more variety in doors," "we need a Hostile Slammer," or "let's do the elders" all qualify.
---

# Go Out and Preach — Character Creation

The canonical pattern for adding characters to this game. Read in full before any work. The pattern was established across M3 (Polite Refuser implementation) and refined through the dialogue subagent handoff. This skill encodes both.

## Required Reading (in this order)

Before generating the plan, read every one of these files in full:

1. `CLAUDE.md` — project conventions, tone guardrails, milestone discipline
2. `docs/STATUS.md` — current milestone, open decisions, recent silent-decisions audits
3. `docs/design/gdd.md` — game design document, especially § 6 (householder archetypes) and § 7 (cast)
4. `docs/design/cast.md` — canonical voice profiles for all named NPCs and archetypes
5. `docs/design/dialogue-context.md` — voice bible (vocabulary, cadence, tone red lines, sample interactions)

Skipping any of these is a defect. The voice work depends on the texture in cast.md and dialogue-context.md; the systems wiring depends on conventions in CLAUDE.md and STATUS.md.

## Decision Tree

Identify the character type before planning:

**Householder archetype** — populates territory houses, encountered at doors.
- Has a Householder resource (`data/dialogues/characters/<archetype>.dch` + `data/householders/<archetype>.tres`)
- May have a full Dialogic timeline OR a minimal scene (Hostile Slammer has no dialogue tree)
- Outcomes route through `TerritoryManager` enum (REFUSED, TRACT_LEFT, RETURN_VISIT_SCHEDULED, possibly extension)
- May have doubt-mechanic special cases (Apostate fires +doubt on REFUSED)

**Named NPC** — recurring character in meetings, family scenes, or social contexts.
- Has a character resource and voice profile but no household
- Surfaces in scene-specific timelines, not door-knock encounters
- May gate progression (Sister Pioneer romance, elder appointment)

**Modification of existing character** — content extension or voice refinement.
- Touch existing files cautiously
- Document changes inline as `# RESOLVED:` comments referencing the decision
- Update STATUS.md with the modification rationale

## Implementation Pattern

Same shape used for M3 Polite Refuser. Phases are non-negotiable.

### Phase 0 — Silent Decisions Audit

Before drafting the plan, audit the prior milestone's code for silent decisions (decisions made without surfacing them to the user). Surface 4–10 audited decisions, classified as:
- **Inert** for this character work — no action needed, log only
- **Material** — must be resolved by this milestone, propose resolution

Pattern verified in M2→M3→M4. Skipping the audit means inheriting accumulated drift.

### Phase 1 — Design Proposal

Surface design decisions BEFORE writing code. Required questions per character:

For an **archetype**:
1. Does this archetype use a full Dialogic timeline or a minimal scene? (Hostile Slammer → minimal; everyone else → full)
2. Exchange count and choice density (GDD § 6 says 3–7 exchanges, choice every 1–2 exchanges per dialogue-context.md § 9)
3. Outcomes reachable (subset of REFUSED, TRACT_LEFT, RETURN_VISIT_SCHEDULED, BIBLE_STUDY_STARTED, or new enum)
4. Portrait count and expression beats
5. Doubt mechanic integration:
   - Standard archetype: triggers existing T1–T4
   - Apostate: requires NEW +doubt-on-REFUSED code path
   - Curious Seeker: may require BIBLE_STUDY_STARTED outcome enum extension
6. Distribution across territory houses (recommended weighting in cast.md § 6 mirrors real ministry — Polite Refuser most common, Apostate rare)

For a **named NPC**:
1. Which scenes does this NPC appear in? (Meeting, family, congregation lobby, phone/text)
2. Does this NPC have a long-form arc (Sister Pioneer romance, Householder of Note crisis) or scene-level appearances only?
3. Portrait count and expression beats
4. Does this NPC gate any progression?
5. How does this NPC integrate with existing systems (doubt triggers from family conflict, standing changes from elder approval)?

Wait for explicit user approval on Phase 1 decisions before any code.

### Phase 2 — Structural Implementation

Write systems and structure. NOT final dialogue text.

For an **archetype with full timeline**:
1. Create `data/dialogues/characters/<archetype>.dch` (Dialogic character resource) with portrait expressions
2. Create `data/householders/<archetype>.tres` (Householder resource) referencing the character
3. Build the Dialogic timeline `data/dialogues/<archetype>_v1.dtl` with:
   - Complete branch structure
   - Choice options with text and outcome routing
   - Portrait expression beats
   - Terminal `[signal arg="OUTCOME"]` events on every branch
   - **All dialogue lines as `# DRAFT PENDING — dialogue subagent run` placeholders**
4. Wire to `TerritoryManager` if archetype is selectable (constants in `territory_manager.gd`)
5. Add the archetype's Householder.tres to the default territory's house assignments
6. Update `data/dialogues/<archetype>.dtl` directory map in `project.godot`

For an **archetype with minimal scene** (Hostile Slammer pattern):
1. Skip the Dialogic timeline entirely
2. Build a tiny scene (door opens, brief beat, door closes) in `door_knock.gd` or a subscene
3. Fire the outcome signal directly without dialogue runner
4. Skip the dialogue subagent pass

For an **Apostate** specifically:
1. Standard archetype implementation per above
2. Plus: add doubt-on-REFUSED special handling in `door_knock.gd::_on_dialogic_signal`
3. Update OUTCOME_DOUBT_DELTAS or introduce per-householder doubt-delta logic
4. STATUS.md notes that this is the first archetype with doubt-mechanic special-case code

For a **named NPC**:
1. Create character resource + voice profile per cast.md entry
2. Build the scene container (meeting hall, family home, phone/text scene)
3. Wire to relevant managers (TimeManager for scheduled scenes, ResourceManager for standing effects)
4. Dialogue placeholders as in archetype pattern

### Phase 3 — Dialogue Subagent Handoff

After structure lands and parses cleanly, the dialogue subagent fills line text in a SEPARATE Claude Code session. This separation is non-negotiable — systems work and content work do not share a session.

The dialogue subagent prompt template:

```
Read these files in full before writing anything:
1. CLAUDE.md
2. docs/design/dialogue-context.md — voice bible
3. docs/design/cast.md — specifically the <CHARACTER_NAME> entry
4. docs/design/gdd.md § 6 (archetypes) or § 7 (cast) as applicable
5. docs/STATUS.md
6. The character's timeline file with "# DRAFT PENDING" placeholders

Your task: replace every "# DRAFT PENDING" placeholder with final dialogue line text per the cadence, vocabulary, and red lines in dialogue-context.md. This is content work, not systems work.

Before drafting:
1. State your interpretation of <CHARACTER_NAME> in 3-5 sentences: who they are, what they want, what discomfort or pressure sounds like in their speech, what they will not do. Reference cast.md and dialogue-context.md sections explicitly.
2. Wait for confirmation or correction before generating any lines.

When drafting (after confirmation):
- Write all sides of the interaction
- Honor the character's voice profile from cast.md
- Apply vocabulary, cadence, and red lines from dialogue-context.md
- Specificity over generality — a specific awkward sentence beats a polished generic one
- Add "# UNSURE: ..." inline comments wherever uncertain about regional, generational, or theological details

Do NOT:
- Modify structure, branch logic, choice counts, or portrait beats
- Add new choices or remove existing ones
- Quote real Watchtower publications, songs, or living leaders
- Write dialogue for other characters in this pass
- Enter plan mode

Output:
- One pass through the file
- All placeholders replaced
- # UNSURE comments where uncertain
- Brief summary: total exchanges written, outcomes reachable, structural concerns noticed (flag only, do not fix)
```

After the subagent completes:
1. Review the draft
2. Apply hand-edits or run a fix prompt for specific corrections
3. Commit content as its own commit (clean diff)

### Phase 4 — Verification

Headless Dialogic parse check via `godot --headless --check-only`. Confirm:
- Timeline parses cleanly
- All outcome signals reachable from start
- Choice topology unchanged from structural plan
- No portrait file references broken

Then gate playtest in Godot editor (user's hands):
- Each terminal path traversable
- Lines read natural in context
- Doubt deltas fire correctly (debug panel via F9)
- Character distribution across territory feels meaningful

### Phase 5 — STATUS Update

Update STATUS.md with:
- Character added, milestone number
- Decisions locked during this work
- Silent decisions audit results
- Any new outcome enum values or doubt mechanic special cases
- Open questions deferred to future milestones
- Post-character playtest priorities

This is non-optional. CLAUDE.md § Milestone Discipline applies to character work as much as to systems work. (M3 dialogue work caused STATUS drift by treating content as non-session — do not repeat this.)

## Special Cases

### Hostile Slammer
Minimum viable archetype. No Dialogic timeline, no dialogue subagent pass. Implementation is a 5–15 second scene: door opens → brief portrait reaction → door closes → REFUSED outcome. Fires T3 (+1 doubt) per existing M4 wiring. Total scope: probably 60 lines of code. Use this archetype as the "we need variety NOW" lever when the project needs content breadth fast.

### Apostate
Most narratively important and most delicate. Three flavors per cast.md § 6.6 (Hostile, Wounded, Gentle). The Gentle Apostate is the highest-doubt-impact NPC in the game. Implementation:
- Standard timeline structure
- New +doubt-on-REFUSED code path (Apostate is the only archetype where positive outcomes still cost)
- Doubt delta calibration is sensitive — propose values in Phase 1, do not silently pick
- Deserves a dedicated session, not a batch add

### Curious Seeker
First archetype that may require BIBLE_STUDY_STARTED outcome enum extension. Surface this decision in Phase 1 — the user may want the new outcome (full content fidelity) or may want to collapse to RETURN_VISIT_SCHEDULED for v0.1 simplicity. Either is defensible.

### Lonely Elderly
Longest interaction by design (20+ minutes in real life). Compress for game pacing: 5–7 exchanges max, but with a unique "extra time cost" — fires double `add_hours` on the door-knock to reflect that this household ate the morning. Consider showing the time-cost increase as feedback ("This visit took longer than expected.").

### Householder of Note
Recurring NPC with arc, not an archetype. Goes through the named-NPC path, not the archetype path. Pick one of the three Margaret/Daniel/Sarah & Tom variants per cast.md § 5.2 before starting. Their arc spans many in-game weeks and intersects multiple systems (doubt, family, blood doctrine plot beat).

### Named Elders
Coordinator of Elders is the most dangerous NPC because he is genuinely kind. The Strict Elder is the constant pressure. Both must be written with dignity — making either a strawman defeats the game. Voice profiles in cast.md §§ 4.1–4.2 are canonical.

## Anti-Patterns to Avoid

- **Skipping the silent-decisions audit.** Drift accumulates silently across milestones.
- **Mixing structure and dialogue in one session.** They are different concerns and the dialogue subagent pattern depends on separation.
- **Modifying M3-validated content.** The Polite Refuser timeline is locked except for explicit edit passes with documented rationale.
- **Generic dialogue.** "I'm not interested" is generic. "Oh — uh, we go to St. Mark's, actually" is specific. Specificity is the whole project.
- **Caricature.** No JW character is stupid, brainwashed, or evil. No householder is a strawman. The empathy bar applies to every line.
- **Quoting real publications.** All scripture-adjacent content is original. The fictional org has its own books (*The Lighthouse*, *Songs of the Truth*) and its own deity-name conventions per dialogue-context.md § 2.
- **Treating Apostate as just another archetype.** It has special mechanics, narrative weight, and authenticity sensitivity. It deserves focused attention.
- **Forgetting STATUS.md updates.** If you touched the codebase in a session, STATUS.md gets an entry.

## Quality Bar

The dialogue subagent's M3 quality bar was: would someone who lived this nod, or wince at how wrong it is? That bar applies to every character. The texture of high-control religion is the product. Get it right or flag uncertainty for the user to resolve.

---

*Skill version 1. Refine after each character milestone — add patterns that emerged, prune what didn't land.*
