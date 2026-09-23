# AGENTS.md — Go Out and Preach

Instructions for AI coding agents other than Claude Code (Codex and similar). Claude Code reads `CLAUDE.md`. **Read `CLAUDE.md` in full before doing anything.** Its tone, legal, engineering, and workflow rules apply to you exactly as written. This file repeats only what's easiest to get wrong.

## The project

A narrative simulation game in Godot 4.6 (GDScript) about a young member of a fictional high-control religious group. Empathetic, not satirical. The design lives in `docs/design/gdd.md`; the current state and decisions are in `docs/STATUS.md` (one page).

## Rules you must not break

1. **Legal guardrails** (CLAUDE.md § Legal). The organization is fictional: *The Society of the Truth*, *The Lighthouse*, the *Hall of Witness*. Never use a real organization's name, logo, publication, song, or leader. That includes prompts for generated images, and anything visible in them. No verbatim text from real religious publications.
2. **Always run Godot through `bash tools/godot.sh <args>`.** Never call the Godot binary directly. An editor-mode import empties the Dialogic tables in `project.godot`, and the wrapper restores the file afterwards.
3. **`bash tools/check.sh` must print `all clean` before every commit.** It imports, boots every scene, runs the tests (content integrity, a 240-run balance simulation, save/load), and plays two full games through the real UI.
4. **Don't edit `addons/dialogic/`** (a vendored plugin) or `.claude/` (Claude Code's configuration).
5. **Work on your own branch** (`codex/<topic>`), never on `main` or a `claude/*` branch. Keep commits small, and write messages that say what changed and why.

## Setup

```bash
bash tools/install_godot.sh        # Godot 4.6.1, Linux x86_64; prints the binary path
bash tools/check.sh                # the full verification
bash tools/screenshot.sh res://scenes/week_view.tscn out.png   # render a real frame (needs Xvfb)
```

## Common tasks

- **Art and images:** follow `docs/design/asset-brief.md`. Every slot is pre-wired: save the PNG at the exact path given, run `bash tools/godot.sh --headless --import`, and commit the PNG together with its `.png.import` file. `bash tools/art_status.sh --missing` lists what's left.
- **Dialogue:** timelines live in `data/dialogues/` (Dialogic `.dtl`). Before writing a line, read `docs/design/cast.md`, `docs/design/dialogue-context.md`, and § 1a of `docs/design/dialogue-style-guide.md`. Two mechanics bite: a speaker needs a `.dch` file (ad-hoc speakers crash Godot on exit), and prose must never start with `Word:`. Mark any line you're unsure is true to lived experience with `# TODO: authenticity check`.
- **Tuning numbers:** constants live in the autoloads under `scripts/systems/`, and `docs/design/v01-loop.md` explains each one. After a change, run `bash tools/godot.sh --headless --script res://tools/ci/run_tests.gd -- --only=balance` and compare the printed table with the one in `docs/STATUS.md`.
- **Design changes:** record the decision under *Decisions made* in `docs/STATUS.md`. That file is overwritten, never appended; keep it to one page.
