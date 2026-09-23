# CLAUDE.md — Go Out and Preach

A narrative simulation game built in Godot 4.x about life inside a fictional high-control millenarian Christian sect. The full design lives in `docs/design/gdd.md`. **Read it before starting any new feature work.**

---

## Starting a Session

Before executing any task:
1. Read this file in full.
2. Skim `docs/design/gdd.md` for the relevant section.
3. Read `docs/STATUS.md` (one page): current focus, decisions awaiting review, next step.
4. For a large systems change, write a short plan first (plan mode or a few bullets in chat).

---

## Running & Verifying

Godot 4.6.1 is installed in Claude Code web sessions by `.claude/hooks/session-start.sh` (`godot` on PATH; `bash tools/install_godot.sh` anywhere else).

- `bash tools/check.sh` — imports, boots every scene, runs the test suite (`tools/ci/tests/`). **Run before every commit; it must print `all clean`.** CI runs the same script.
- `bash tools/screenshot.sh res://scenes/<scene>.tscn out.png [setup.gd]` — renders a real frame under Xvfb. Use it to *look at* UI changes; a setup script can stage game state first (see `tools/ci/screenshot.gd`).
- `bash tools/godot.sh <args>` — run Godot on this project for anything else. Always go through this wrapper: it restores `project.godot`, whose Dialogic tables an import would otherwise empty.

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
- **Dialogue runner:** Dialogic 2 (alpha, vendored in `addons/dialogic/`). Upgrade deliberately, never incidentally. All dialogue lives external to `.gd` files.
- **Save format:** Godot resource serialization at week boundaries plus three manual slots.

Don't add new plugins or dependencies without flagging the request in the session.

---

## Engineering Conventions

### File organization
Follow the structure in `docs/design/gdd.md` § 11. Don't invent new top-level directories without updating the GDD first. Dev tooling lives in `tools/`, CI in `.github/`.

### Naming
- Scenes: `snake_case.tscn`
- Scripts: `snake_case.gd`, matching their scene when attached
- Resources: `snake_case.tres`
- Signals: past-tense events (`week_advanced`, `doubt_threshold_crossed`)
- Autoload singletons: `PascalCase` (`TimeManager`, `PlayerState`, `DoubtMeter`)

### Data discipline
- Householders, NPCs, events, territories: all `Resource` subclasses, serialized as `.tres`
- Conversations and scenes with characters live in `data/dialogues/` as Dialogic timelines — never in `.gd` files
- Short screen copy (button labels, one-line flavor, report lines) may sit in the script that shows it, as a clearly named const table; move it to data when it grows or needs variants
- All user-facing strings wrapped in `tr()` for future localization

### Code style
- Type hints required on all function signatures and class members
- Prefer signals over direct cross-system calls
- One class per file, filename matches class name
- Split a script when it mixes unrelated jobs; length alone (~300+ lines) is a prompt to look, not a rule
- Comments describe what the code does and why. Milestone / phase / session history belongs in commit messages, not comments

### Don't
- Don't optimize prematurely — readable beats clever in a 2D narrative sim
- Don't refactor working code unprompted

---

## How We Work

The original M0–M8 plan (`docs/design/gdd.md` § 13) got the scenes built. The current phase is **making v0.1 fun**: one full run from New Game to an ending that holds a tester, played without debug keys.

1. **Loop before content.** Until a full run is compelling, a change that makes choices matter beats a new character, portrait, or polish pass.
2. **Small playable steps.** Each commit leaves a working build (`tools/check.sh` clean). System and content changes may share a commit when the content is what exercises the system.
3. **Design calls.** When the GDD doesn't answer something mechanical (a cost, a threshold, a pacing number), make the smallest reasonable call, keep it in one tunable constant or data file, and list it under *Decisions to review* in `docs/STATUS.md`. Stop and ask before inventing **narrative beats for named characters, art direction, or anything near the legal guardrails** — and never guess at lived-experience detail (stub `# TODO: authenticity check`).
4. **`docs/STATUS.md` stays one page.** Overwrite it at the end of each session: what's playable, current focus, decisions to review, open questions, next step. History goes in commit messages, not STATUS. (The May 2026 log is in `docs/archive/`.)
5. If a task seems to conflict with this CLAUDE.md or the GDD, flag the conflict before resolving it.

---

## Common Pitfalls

- **Inventing JW-adjacent details without research.** Real practice is specific. When in doubt, leave a comment and ask.
- **Making the doubt meter visible too early.** Hidden until threshold 40, fully visible at 70. Don't expose it in debug UI by default — there's a debug flag for that.
- **Dialogue that's too explicit about the system's flaws.** The game's power lives in the player noticing things, not the game pointing them out. Trust the player.
- **Over-engineering the save system.** Resource serialization at week boundaries is enough. This is a narrative sim, not an MMO.
- **Generic "AI fantasy" tropes.** No glowing magic effects, no orchestral swells at emotional beats, no Hollywood pacing. Restraint everywhere.

---

## Subagent Notes

Subagents are optional; most work is faster in one session. If you do parallelize:
- Each subagent reads this CLAUDE.md and the relevant GDD section
- Content subagents (dialogue, householders) can work in parallel; system changes to shared autoloads (`TimeManager`, `ResourceManager`, `DoubtMeter`, `GameState`) go through one session

---

## Reference Documents

- `docs/design/gdd.md` — game design document (canonical)
- `docs/design/cast.md`, `docs/design/dialogue-context.md` — character voices and vocabulary; read before writing any line
- `docs/design/authenticity-notes.md` — lived-experience texture notes (Andrew populates)
- `docs/design/dialogue-style-guide.md` — voice and cadence guide
- `docs/STATUS.md` — one page: what's playable, current focus, decisions to review, next step
- `docs/BACKLOG.md` — wanted but unscheduled ideas
- `docs/archive/` — superseded logs, kept for history
