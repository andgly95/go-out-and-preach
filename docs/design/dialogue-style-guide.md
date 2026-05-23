# Dialogue Style Guide — Go Out and Preach

> The "how to write a shippable line" companion to
> [dialogue-context.md](./dialogue-context.md). That doc is the voice
> bible (vocabulary, theology, archetype profiles, cadence). This one
> is the mechanical style guide: line length, choice phrasing, stage
> directions, and what to flag.

Created M3 as a stub. Body sections marked **DRAFT** are populated
after the dialogue subagent's first authoring pass, when concrete
patterns will have emerged. Filling them in earlier would invent
rules from outside lived experience.

---

## 1. Purpose

Dialogue agents must read `dialogue-context.md` in full before writing
any line. This style guide is read second, and only governs surface
form: how long a line is, how a choice is phrased, how a stage
direction is written. The *content* lives in dialogue-context.md.

---

## 2. Line length norms

**DRAFT — populated after dialogue subagent first pass.** Expected
target: short to medium beats, no monologues. Real door interactions
are clipped. Specific token/sentence ceilings will land here once
we see a draft and can react to what feels right vs. wrong in play.

---

## 3. Choice phrasing norms

**DRAFT — populated after dialogue subagent first pass.** Expected
guidance: choices are written in the Publisher's voice (first
person), not as meta-descriptions of intent ("Be polite" — no;
"Of course, we respect that." — yes). Off-script choices should
read as something a person could actually say, not a label.

---

## 4. Stage directions and engine calls

**DRAFT — populated after dialogue subagent first pass.** Expected
patterns:
- `update charactername (expression)` for portrait swaps.
- `[signal arg="OUTCOME"]` for terminal nodes only.
- `[end_timeline]` after every signal so branches don't fall through.
- `# DRAFT PENDING — dialogue subagent run` for placeholder text
  prior to the dialogue subagent run.
- `# AUTHENTICITY: ...` for notes the subagent leaves for Andrew.
- `# UNSURE: ...` for lines the subagent isn't confident about per
  `dialogue-context.md` § 11.

---

## 5. Flagging unsure content

Re-states `dialogue-context.md` § 11: when in doubt, leave the line
text as `# DRAFT PENDING — dialogue subagent run` plus a `# UNSURE:`
comment explaining what to verify. Better to flag than to ship
a generic line. Andrew catches off-notes faster reading a flagged
draft than reading clean prose.

---

## 6. Examples

**DRAFT — populated after dialogue subagent first pass.** Two or
three concrete before/after pairs from the Polite Refuser draft —
what a generic line looks like, what a specific line looks like,
what made the difference. Wait for real material to anchor these.
