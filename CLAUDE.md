# CLAUDE.md — Go Out and Preach

A narrative simulation game built in Godot 4.x about life inside a fictional high-control millenarian Christian sect. The full design lives in `docs/design/gdd.md`. **Read it before starting any new feature work.**

---

## Starting a Session

Before executing any task:
1. Read this file in full.
2. Skim `docs/design/gdd.md` for the relevant section.
3. Check `docs/STATUS.md` for current milestone and open work.
4. If the task is systems work, enter **plan mode (Shift+Tab)** and produce a written plan before code.

---

## Tone & Authenticity

This game is **empathetic, not satirical**. Even the most rigid NPC is written as a person who believes they are doing good. Mood reference: *Disco Elysium* and *Pathologic*. Not *South Park*, not *Bojack*, not horror.

Authenticity comes from:
- Specific vocabulary used naturally (publisher, service group, return visit, etc. — using the fictional org's terms, see Legal below)
- The cadence of how people in high-control religious groups actually speak
- Mundane texture (parked cars before meetings, the social weight of who sits where, the small humiliations of door knocking)

Authenticity is NOT:
- Quoting real Watchtower publications, Kingdom Melodies, or trademarked illustrations
- Caricature, mockery, or condescension toward believers
- Generic "cult" tropes from horror media

**When unsure about dialogue content, stub it with `# TODO: authenticity check` and ask.** Never guess at lived-experience details.

---

## Legal Guardrails (non-negotiable)

- Fictional organization: **The Society of the Truth**
- Publication: ***The Lighthouse***
- Meeting space: **Hall of Witness**
- Endearments: "brothers and sisters," "friends in the Truth"
- The "end times": **the New System**

Never use:
- Real organization names, trademarks, or logos
- Verbatim quotes from real religious publications
- Real song lyrics, melodies, or hymn structures
- Names of real living religious leaders

Lean on original framing rather than parodying real material. The flavor comes from systems design and cadence, not from lifting.

---

## Tech Stack

- **Engine:** Godot 4.x (latest stable)
- **Language:** GDScript primary. C# only if a specific system genuinely requires it — justify in the commit message.
- **Dialogue runner:** Dialogic plugin (pending final decision in M3). All dialogue lives external to `.gd` files regardless of choice.
- **Save format:** Godot resource serialization at week boundaries plus three manual slots.

Don't add new plugins or dependencies without flagging the request in the session.

---

## Engineering Conventions

### File organization
Follow the structure in `docs/design/gdd.md` § 11. Don't invent new top-level directories without updating the GDD first.

### Naming
- Scenes: `snake_case.tscn`
- Scripts: `snake_case.gd`, matching their scene when attached
- Resources: `snake_case.tres`
- Signals: past-tense events (`week_advanced`, `doubt_threshold_crossed`)
- Autoload singletons: `PascalCase` (`TimeManager`, `PlayerState`, `DoubtMeter`)

### Data discipline
- Householders, NPCs, events, territories: all `Resource` subclasses, serialized as `.tres`
- Never hardcode dialogue, NPC names, or content strings in `.gd` files
- All user-facing strings wrapped in `tr()` for future localization
- Dialogue lives in `data/dialogues/` as external files (Dialogic timelines or `.ink`)

### Code style
- Type hints required on all function signatures and class members
- Prefer signals over direct cross-system calls
- One class per file, filename matches class name
- Keep scripts under 200 lines — refactor into components if a script grows past that

### Don't
- Don't optimize prematurely — readable beats clever in a 2D narrative sim
- Don't refactor working code unprompted
- Don't mix system work and content work in the same session — they ship as separate commits

---

## Milestone Discipline

Project is structured into M0 – M8 (see `docs/design/gdd.md` § 13).

1. **Work one milestone per session.** Don't run ahead, don't combine milestones.
2. **End each session with a working build.** No half-merged systems.
3. **If a milestone needs a design decision the GDD doesn't answer**, stop and ask. Don't guess on doubt thresholds, dialogue gating, narrative beats, or art direction.
4. **Core loop validation gate at M3.** The door-knock minigame must feel emotionally compelling. If it doesn't, stop and redesign before building M4+. This is a real gate, not a formality.
5. **Update `docs/STATUS.md`** at the end of every session: completed work, open questions, next-session entry point.

---

## When You're Stuck

If a task is ambiguous or the design doesn't address it:
1. Check the GDD's "Open Design Questions" section (§ 15)
2. If still unclear, propose 2-3 specific interpretations and ask which to take
3. Never silently choose one and proceed

If a task seems to conflict with this CLAUDE.md or the GDD, flag the conflict before resolving it.

---

## Common Pitfalls

- **Inventing JW-adjacent details without research.** Real practice is specific. When in doubt, leave a comment and ask.
- **Making the doubt meter visible too early.** Hidden until threshold 40, fully visible at 70. Don't expose it in debug UI by default — there's a debug flag for that.
- **Dialogue that's too explicit about the system's flaws.** The game's power lives in the player noticing things, not the game pointing them out. Trust the player.
- **Over-engineering the save system.** Resource serialization at week boundaries is enough. This is a narrative sim, not an MMO.
- **Generic "AI fantasy" tropes.** No glowing magic effects, no orchestral swells at emotional beats, no Hollywood pacing. Restraint everywhere.

---

## Subagent Notes

When parallelizing with subagents in worktrees (M5+):
- Each subagent reads this CLAUDE.md and the relevant GDD section
- Subagents do not edit shared singletons (`TimeManager`, `PlayerState`, `DoubtMeter`) without explicit coordination
- All subagent work lands in its own worktree and integrates through a dedicated merge session
- Content subagents (dialogue, householders) can work fully in parallel
- System subagents (new managers, scene scaffolding) serialize through main

---

## Reference Documents

- `docs/design/gdd.md` — game design document (canonical)
- `docs/design/authenticity-notes.md` — lived-experience texture notes (Andrew populates)
- `docs/design/dialogue-style-guide.md` — voice and cadence guide (created M3)
- `docs/STATUS.md` — current milestone, open work, next-session entry point
