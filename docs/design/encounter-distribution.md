# Encounter Distribution — Field Service Door Outcomes

> Per-door probability table and session-pacing parameters for the field service minigame. Sibling document to `cast.md` (archetype voices) and `dialogue-context.md` (cadence). Read alongside both when implementing the encounter roller.

This document specifies:
1. How many doors a publisher knocks per field service session
2. What outcome rolls when each door is knocked
3. Modifiers that bend those numbers (territory type, ongoing conversation, doubt state)

It does **not** specify dialogue. It specifies frequencies. Dialogue lives in `data/dialogues/`.

---

## 1. Source Note

No official Watchtower-published statistics exist for door-outcome taxonomies. The org publishes hours, placements, return visits, and baptisms — not refusal breakdowns. The numbers in this document are reasoned estimates synthesized from:

- Ex-publisher community reports (r/exjw field service logs, JWfacts, jwsurvey)
- General door-to-door canvassing response-rate literature (political, religious, sales)
- Lived-experience texture notes — flag any number here that conflicts with `authenticity-notes.md` once that doc is populated

**Regional variance is large.** Bible Belt vs. Quebec vs. NYC apartment block vary by factors of 2–5x on individual archetype rates. The table below targets a generic suburban North American setting, which is the game's implied default territory until territory-system work (M4) says otherwise.

Treat these numbers as v1. Refresh after M4.2 playtest tells us whether the cadence feels right.

---

## 2. Session Door Count

A standard field service session is **~1.5–2 hours of active door work** after the meeting-for-service, the drive to territory, and the inevitable coffee break.

### 2.1 By territory type

| Territory type | Doors per session | Notes |
|---|---|---|
| Suburban dense (subdivision) | 25–40 | Default game territory |
| Suburban spread (large lots, long driveways) | 15–25 | |
| Apartment building (accessible) | 40–60 | Highest throughput |
| Rural | 8–15 | Driving kills the count |

### 2.2 Game default

**25 doors per session** is the baseline target for the v0.1 minigame. Variance pulled by:

- **Territory type:** apply the range above
- **Long-conversation absorption:** a Curious Seeker or Lonely Elderly encounter consumes 20–30 in-game minutes and reduces remaining doors in the session by 30–40%
- **Publisher type:** the player is a regular publisher (~10 hrs/month). Pioneer NPCs do 3–4 hour sessions and hit 40–60 doors — relevant if the partner is a pioneer and the session length scales

### 2.3 Suggested implementation

```
session_door_budget = base_doors * territory_modifier
for each door in session_door_budget:
    if active_long_conversation:
        session_door_budget -= absorbed_doors
    roll outcome from §3 table
```

---

## 3. Per-Door Outcome Table

Each roll happens when the publisher approaches a door. Probabilities sum to 100%.

| Outcome | Probability | Notes |
|---|---|---|
| `NOT_HOME` | 70.0% | Default modal outcome. No knock-answer, no interaction. |
| `POLITE_REFUSER` | 17.0% | The dominant *answered-door* outcome. See `dialogue-context.md` § 6. |
| `HOSTILE_SLAMMER` | 4.0% | Logged in real publisher records as `NOT_HOME` or `REFUSED` depending on whether words were exchanged. In-game, distinguish — the texture matters. |
| `NO_ANSWER_BUT_HOME` | 3.5% | Door cracks and shuts, curtain twitches, footsteps retreat. No archetype triggered. Atmospheric only. |
| `HOSTILE_CHRISTIAN` | 2.0% | Regional. Bake into territory variance later. |
| `LONELY_ELDERLY` | 1.5% | Overrepresented in retirement-heavy territories. |
| `DISILLUSIONED_CATHOLIC` | 1.0% | Regional (Catholic population density). |
| `CURIOUS_SEEKER` | 0.7% | Rare per door. Memorable. |
| `APOSTATE` | 0.2% | See §4 for the three-flavor sub-roll. |
| `HOUSEHOLDER_OF_NOTE` | 0.1% | Recommended: gate to designated territory houses, not random — see §5. |

### 3.1 Sanity check at 25 doors/session

A typical 25-door session produces:
- ~17–18 not-home
- ~4–5 polite refusers
- ~1 hostile or weird interaction
- A rare archetype (Curious Seeker, Lonely Elderly, Disillusioned Catholic) every 2–3 sessions
- An Apostate every ~20 sessions (~5 in-game months at one session/week)

This cadence matches what former publishers describe and gives the doubt meter time to breathe between charged encounters. **If the player meets an Apostate every session, the game is mis-tuned.** Rarity is the design.

---

## 4. Apostate Sub-Roll

When `APOSTATE` rolls, sub-roll for flavor:

| Flavor | Sub-probability | Doubt increment (per `cast.md` § 6.6) |
|---|---|---|
| Hostile | 40% | Moderate |
| Wounded | 35% | High |
| Gentle | 25% | Highest |

The Gentle Apostate is the rarest and the most dangerous to the player's doubt meter — that asymmetry is intentional.

---

## 5. Householder of Note

**Do not roll randomly.** The Householder of Note is a long-arc character (`cast.md` § 5.2) and should occupy a fixed house in a designated territory. The 0.1% in §3 represents the per-door probability *only when the player works that designated territory*; in other territories it is 0%.

Suggested rule:
- One Householder of Note house per assigned territory
- First encounter triggers when the player reaches that house in the territory grid
- Subsequent encounters are scheduled by the Householder of Note's own narrative arc, not by the encounter roller

Open question (defer to M5): does the player choose which Householder of Note ships (Margaret / Daniel / Sarah & Tom), or is it fixed per playthrough?

---

## 6. Modifiers

### 6.1 Territory-driven (applied to §3 base rates)

| Territory archetype | Modifies | Effect |
|---|---|---|
| Retirement-heavy | `LONELY_ELDERLY` | ×2.5 |
| Catholic-heavy (Northeast US, Quebec equivalent) | `DISILLUSIONED_CATHOLIC` | ×3 |
| Bible Belt equivalent | `HOSTILE_CHRISTIAN` | ×4 |
| Apartment dense | `NOT_HOME` | ×0.8 (more answers), `HOSTILE_SLAMMER` | ×1.3 |
| Working-class weekday morning | `NOT_HOME` | ×1.1 |
| Suburban Saturday morning | `NOT_HOME` | ×0.9 |

Rebalance the residual probability mass into `POLITE_REFUSER` so the total stays at 100%.

### 6.2 Doubt-state driven

The Apostate Gentle flavor's potency scales with the player's existing doubt state. This is **not** a probability modifier — the rate of encountering an Apostate stays constant. The damage scales:

- Doubt < 40: increment as listed in `cast.md`
- Doubt 40–70: increment ×1.25
- Doubt > 70: increment ×1.5

The Apostate's role is to land hardest when the player is already cracking.

### 6.3 Player-state driven

If implemented later:
- Recent meeting attendance high → small reduction in doubt increment from all archetypes
- Service partner is the recurring core partner (`cast.md` § 4.4) → conversation absorption is more likely (the partner stays for the Lonely Elderly's third story)

---

## 7. What This Document Does NOT Cover

- **Return visits.** The encounter roller is for first contacts. Return visits and Bible studies are scheduled by the player's choices, not rolled. M6 work.
- **Dialogue branching within an archetype.** That belongs in the dialogue timelines themselves.
- **Reactions of the publisher partner.** Partner behavior during encounters is dialogue/scripting work, not probability work.
- **Time of day / day of week.** Implied by the modifiers in §6.1 but not yet a formal axis. Add when the day-screen system supports varying service slots.

---

## 8. Open Questions

1. Should `NO_ANSWER_BUT_HOME` be a discoverable game state (player can flag the house for return) or pure atmosphere?
2. Is the Apostate's per-door probability constant across all territories, or does it rise slightly in apartment-dense urban territory (where ex-members concentrate)?
3. Do we want a "memorable encounter" floor — e.g., guarantee at least one non-refuser interaction per session — to keep sessions from feeling like 25 not-homes in a row?
4. Should regional/cultural territory archetypes (§6.1) be authored as named territory `.tres` resources, or as modifier tags applied to generic territories?

Resolve as territory-system work (M4.3+) lands.

---

*End of encounter-distribution v1. Refresh after M4.2 playtest. Numbers here are starting points, not load-bearing claims.*
