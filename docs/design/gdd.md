# Go Out and Preach
## High-Concept Game Design Document

> A narrative simulation about belief, belonging, and the quiet erosion of certainty inside a high-control millenarian Christian sect. Built in Godot 4.x. Designed for Claude Code agent execution.

---

## 1. Pitch

You are a young publisher in **The Society of the Truth**, a fictional global high-control Christian sect awaiting the imminent end of the world system. You knock doors, attend meetings, manage your standing with the elders, navigate family expectations, and try to keep your faith intact as small doubts accumulate beneath the surface. Over two in-game years, the player makes a thousand small decisions that quietly determine who they become.

Not satire. Not horror. A slow, observational character study in the register of *Disco Elysium* and *Pathologic*, with the structural pacing of *The Shrouded Isle* and the dialogue density of *Cultist Simulator*.

**Reference North Star:** if *Disco Elysium* is about a man losing himself in a city, this is about a person losing themselves in a system that loves them on conditions.

---

## 2. Core Pillars

1. **Authenticity over allegory.** The texture of life inside this kind of organization is the product. Vocabulary, rhythm, social dynamics, and theological framing must feel correct to someone who lived it.
2. **Doubt as the central mechanic.** A hidden meter that quietly reshapes available choices. The player feels their character changing under them.
3. **No villains.** Every NPC, including the elders, believes they are doing good. The tension lives in incompatible love.
4. **Time as enemy and ally.** Weeks compress. Routines repeat. The grind itself is part of the meaning.
5. **Quiet endings.** No final boss. The ending is what the player has become.

---

## 3. Legal & Tone Guardrails

- The fictional organization is **The Society of the Truth**. Their publication is *The Lighthouse*. Their meeting hall is the **Hall of Witness**. Avoid Watchtower trademarks, illustrations, song lyrics, and verbatim publication text.
- Theology echoes JW belief structure (millenarian, anti-Trinitarian, disfellowshipping, blood doctrine, end times) but uses fictional terminology and original scripture interpretations.
- Dialogue draws from the *cadence* of real high-control religious speech, not from copyrighted material.
- Tone is empathetic, never mocking. Even the most rigid elder is written as a person.

---

## 4. Core Loop

The time unit is **the week**. Each week has fixed phases the player navigates:

```
SUNDAY    → Public Talk + Lighthouse Study (meeting scene)
MONDAY    → Personal time / family / secular work (background)
TUESDAY   → Midweek Meeting (meeting scene)
WEDNESDAY → Personal time
THURSDAY  → Service prep / return visit prep (light)
FRIDAY    → Personal time
SATURDAY  → Field Service (territory map + door-knock minigame)
```

Each phase advances three things:
1. **Resource meters** (hours, energy, standing)
2. **Relationship states** (elders, service partners, family, householders)
3. **Hidden doubt accumulation**

End of every week: a brief "reflection" scene where the player journals (sets next week's intent: pioneer hours target, study focus, social effort).

---

## 5. Systems

### 5.1 Resources (visible to player)

| Resource | Range | Purpose |
|---|---|---|
| **Field Service Hours** | 0 – ∞ per month | Drives pioneer eligibility, elder approval. Reset monthly. |
| **Energy** | 0 – 10 per day | Caps actions per phase. Recovered by sleep, meetings (for the devout), private time. |
| **Standing: Elders** | -100 to +100 | Gates appointments (auxiliary pioneer, ministerial servant if male). |
| **Standing: Congregation** | -100 to +100 | Social warmth, invitations, gossip protection. |
| **Standing: Family** | -100 to +100 | Tension at home, support during crisis. |
| **Conviction** | 0 to 100 | The "faith" meter. Visible. Rises with meeting engagement, prayer, successful service. |

### 5.2 Doubt (hidden until threshold)

A second hidden meter, 0 – 100. Not shown in UI until it crosses **40**, at which point a faint, ambiguous indicator appears (a recurring dream, a phrase that catches on rereading, a flicker in dialogue). Fully visible at **70**.

**Increments** (sample triggers):
- Witnessing elder hypocrisy
- A loving disfellowshipping conversation
- A householder's argument that lands
- A failed prayer in a moment of need
- Reading something you shouldn't (a "worldly" book, an apostate website in a curiosity scene)
- Family conflict over doctrine
- A "spiritual experience" that doesn't arrive
- The blood transfusion plot beat (mid-game)

**Decrements**:
- Successful meetings
- Field service that ends in a return visit
- Elder affirmation
- Confession scenes (admitting struggle to a trusted figure)

**Gating effect:** dialogue options exist that the player cannot select below certain doubt thresholds. They appear in greyed-out form so the player knows they're missing something, but can't see what.

### 5.3 Relationships

NPCs have **affection** and **respect** (orthogonal axes). High affection / low respect = pity. High respect / low affection = formality. Each major NPC has 3–5 narrative beats unlocked by combinations.

### 5.4 Appointments & Privileges

Tracked progression:
- **Unbaptized publisher** (start, if player chose pre-baptism opening)
- **Baptized publisher**
- **Auxiliary pioneer** (30 hr/mo, temporary)
- **Regular pioneer** (50 hr/mo, ongoing commitment)
- **Ministerial servant** (males only — game lets player choose to play female, in which case this branch is replaced by congregation roles like sound system, magazine display)
- **Elder** (very late, very rare path)

Each unlock changes what scenes are available and what the elders ask of the player.

---

## 6. The Door-Knock Minigame

The signature moment-to-moment gameplay.

### Flow

1. Territory map (top-down, grid of ~12 houses per territory).
2. Click a house → scene transitions to porch view (character portrait of householder, house background).
3. 3-7 exchange dialogue tree. Player picks responses, householder responds based on archetype + prior history.
4. Resolution → return to map. House marked: Not Home / Refused / Tract Left / Return Visit / Study Started.
5. Hours tick forward.

### Householder Archetypes (v1 set)

| Archetype | Tone | Best Outcome |
|---|---|---|
| **Hostile Slammer** | Door closes immediately | Not Home next time |
| **Polite Refuser** | Kind but firm | Tract Left |
| **Curious Seeker** | Genuinely interested | Return Visit, Study Started |
| **Lonely Elderly** | Wants to talk about anything | Return Visit (low conversion, high time cost) |
| **Disillusioned Catholic** | Open to alternatives | Study Started |
| **Hostile Christian** | Wants to argue Trinity | Theological combat dialogue |
| **The Apostate** | Former member, knows the rebuttals | Doubt +5, lingering effect |
| **The Householder of Note** | Recurring NPC, has a name and arc | Long-form storyline |

### The Householder of Note

One per territory. They become a major NPC. Their arc plays out over months of return visits. They may convert and join the player's life. They may apostatize at the worst moment. They may die in a hospital crisis (blood doctrine plot beat). The player chooses them implicitly by which house they keep visiting.

---

## 7. Cast (v1)

**Player Character:** name, gender, family situation chosen at start. Pre-set as 22-year-old, raised in the Truth, just baptized.

**Family:**
- **A parent "in the Truth"** — fiercely devout, watching for signs of weakness
- **A sibling drifting** — quietly fading, the player can support or report them
- **A grandparent** — the warm one, may need a blood transfusion in mid-game

**Congregation:**
- **The Coordinator of Elders** — kind, patriarchal, deeply convinced
- **The Strict Elder** — sees every infraction, asks hard questions
- **The Sister Pioneer** — model publisher, possibly a romantic interest if same-sex preference matches, but only inside the rules
- **Your Service Partner** — rotates, but one recurring partner becomes a friend/love interest
- **The Sister Who Talks** — gossip vector, useful and dangerous

**Outside:**
- **A "worldly" coworker** — surfaces by text/phone scene, becomes a window
- **The Householder of Note** — see above

**Total speaking NPCs in v1: ~12.**

---

## 8. Endings

Triggered by combinations of Conviction, Doubt, Standing, and key plot beats.

1. **Pioneer** — Conviction high, Doubt low, Elder standing high. Routine becomes life.
2. **Theocratic Marriage** — partnered with a Witness, fade to family scene years later.
3. **Slow Fade** — stop attending. No drama. The phone stops ringing eventually.
4. **Disfellowshipped** — caught in a sin (defined by player's choices), shunned by family.
5. **Awakened Apostate** — Doubt maxed, leaves intentionally, contacts ex-members.
6. **Stay In Doubt** — worst ending. Keep all masks up forever. Visible cracks.

Endings show a "five years later" snapshot scene, not a credits roll.

---

## 9. Art Direction

- **Visual style:** painterly 2D, muted palette. Suburban America with a slight oversaturated nostalgia, like *Kentucky Route Zero* if it were less surreal.
- **UI:** typography-led, sepia + slate blue + cream. Inspired by mid-century religious publication design without copying it. Serifs for diegetic text (the Lighthouse magazine, scripture), clean sans for system UI.
- **Character portraits:** half-body, 3-5 expressions each, 512×768 PNG with transparent background. Soft painterly rendering.
- **House/porch backgrounds:** 1920×1080 painted scenes, ~15 unique houses per territory.
- **Territory map:** top-down tilemap, 64×64 tiles, suburban grid theme. Houses are clickable nodes.
- **Meeting hall:** one painted interior, modular for camera angles.
- **Home / family scenes:** one painted living room, kitchen, bedroom.

**Audio:**
- Ambient pads under exploration
- Acoustic guitar / pump organ for meetings (originals, not real Kingdom Melodies)
- Field-recording style for outdoor service: birds, distant lawnmower, doorbells
- Sparse, intentional. Long silences allowed.

---

## 10. Technical Spec

- **Engine:** Godot 4.x (latest stable)
- **Language:** GDScript primary, C# only if a system demands it
- **Dialogue:** Dialogic plugin OR Ink integration via godot-ink. Decision in M3.
- **Save system:** Godot resource serialization (`Resource.save()`). One slot autosaves at week boundaries; three manual slots.
- **Resolution:** 1920×1080 native, scalable to 16:9 ratios.
- **Platforms (v1):** Windows + macOS desktop builds. Linux as time permits. No mobile.
- **Localization:** English only for v1. Extract all strings via Godot's `tr()` from day one.

---

## 11. Project Structure

```
res://
  scenes/
    main_menu.tscn
    week_view.tscn
    territory_map.tscn
    door_knock.tscn
    meeting_hall.tscn
    home.tscn
    journal.tscn
  scripts/
    systems/
      time_manager.gd        # week phase advancement
      resource_manager.gd    # hours, energy, standing
      doubt_meter.gd         # hidden meter, threshold events
      relationship_manager.gd
      save_load.gd
    entities/
      player_state.gd
      npc.gd
      householder.gd
      dialogue_runner.gd
    ui/
      hud.gd
      portrait_display.gd
      choice_button.gd
  data/
    householders/*.tres
    npcs/*.tres
    dialogues/*.ink (or .json)
    territories/*.tres
    events/*.tres            # doubt-triggering and decrement events
  assets/
    sprites/portraits/
    sprites/houses/
    sprites/tiles/
    audio/music/
    audio/sfx/
    fonts/
  ui/
    themes/
    icons/
  addons/
    dialogic/ (or godot-ink/)
```

---

## 12. MVP Scope (v0.1)

**Goal: prove the core loop is emotionally compelling before scaling content.**

Ship:
- One territory, 12 houses
- One playable in-game week, repeatable
- 3 householder archetypes implemented (Polite Refuser, Curious Seeker, Apostate)
- 1 elder, 1 service partner, 1 family member with at least one scene each
- All resource meters functional
- Doubt mechanic functional with 4 trigger events and 2 decrement events
- Save/load at week boundaries
- Main menu, settings, and one ending stub (Slow Fade)

Out of scope for v0.1:
- Multiple territories
- Romantic arcs
- Appointment progression
- Disfellowshipping system
- All endings except stub

**v0.1 success criterion:** a playthrough of one in-game month makes a tester feel a specific something. If it doesn't, the design is wrong, not the content.

---

## 13. Milestone Plan (for Claude Code agent execution)

Designed for orchestrated subagents. Each milestone is independently testable.

### M0 — Scaffold (1 session)
- Godot project initialized with structure above
- Main menu scene with New Game / Continue / Settings / Quit
- Scene loader and global signal bus
- Empty `player_state.gd` singleton

### M1 — Time & Resources (1 session)
- `time_manager.gd` with week phase enum and advancement
- `resource_manager.gd` with all meters
- HUD displaying visible meters
- Week-view scene showing current day, available actions

### M2 — Territory & Door-Knock Shell (1-2 sessions)
- `territory_map.tscn` with 12 clickable house nodes
- `door_knock.tscn` with portrait + background + dialogue panel
- Houses persist state (visited / not home / etc.)
- Hours tick forward correctly

### M3 — Dialogue System (1-2 sessions)
- Decide Dialogic vs. Ink, integrate
- Implement one full householder conversation tree (Polite Refuser)
- Branching choices wired to outcomes
- Portrait expression changes on key beats

### M4 — Doubt Mechanic (1 session)
- `doubt_meter.gd` with hidden state
- Threshold-based dialogue option gating in dialogue runner
- 4 trigger events and 2 decrement events implemented
- Threshold 40 reveal animation (subtle UI flicker)

### M5 — Meeting Scenes (1 session)
- `meeting_hall.tscn` with seating, speaker portrait, audience
- Two meeting types: Sunday Public Talk, Tuesday Midweek
- Light dialogue scene with social positioning choices
- Conviction/Standing effects

### M6 — Family & Home (1 session)
- `home.tscn` with parent NPC, one scene per week
- Family standing effects, doubt triggers (a parent's comment lands wrong)

### M7 — Save/Load + Polish (1 session)
- Save resource serialization
- Three manual slots + autosave
- Pause menu
- Settings (audio, fullscreen)
- One ending stub (Slow Fade triggers if no field service in 4 weeks)

### M8 — v0.1 Lock (1 session)
- Bug pass
- Balance tuning
- One full playable month from new game to first ending stub
- Tester build

**Total estimated sessions: 9-11.** Realistic calendar: 4-6 weekends of focused work.

---

## 14. Notes for the Agent

- Prioritize **system clarity over feature volume**. A working doubt mechanic with 4 triggers beats a half-built mechanic with 20.
- **Test the core loop early.** If the door-knock minigame doesn't feel good by M3, stop and redesign before building meetings.
- **Dialogue is content, not code.** Keep dialogue in external `.ink` or `.json` files so it can be edited without recompiling logic.
- **Resource files everywhere.** Householders, NPCs, events, dialogues all as Godot `Resource` subclasses. Easy to author, easy to extend, easy for separate subagents to add content in parallel.
- **No premature optimization.** This is a 2D narrative sim. The frame budget is generous. Readable code beats clever code.
- **Authenticity check:** when writing dialogue, the test is "would someone who lived this nod, or wince at how wrong it is?" Lean into specificity. Real groups have specific rhythms.

---

## 15. Open Design Questions

To resolve as the prototype reveals truth:

1. Does the player choose their gender at start, or is it determined by family setup?
2. Is romance a system or a scripted arc?
3. How does the game handle real-time pacing — does a week take 20 minutes or 60?
4. Are there choices the player can't take back, or does every week reset some state?
5. How explicit is the doubt UI at threshold 70 — a number, a phrase, a sound?
6. Does the game ever break the fourth wall (a doubt event where the player sees the meter for the first time)?

These are intentionally unresolved. The prototype answers them.

---

*End of v1 design document. Iterate after M3 prototype playtest.*
