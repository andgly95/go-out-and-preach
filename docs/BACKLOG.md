# Backlog

Unscheduled feature ideas. Anything here is *wanted* but not yet slotted into a milestone. When something graduates, move it into `docs/design/gdd.md` § 13 and/or `docs/STATUS.md`.

Format: one bullet per idea. Add a short *why* if the motivation isn't obvious from the title. Group loosely by area; don't over-organize.

---

## Systems

- **Weekday occupation track.** Player has a daytime life on weekdays: school (with worldly classmates/teachers), secular job (worldly coworkers, situations that pressure conscience), or full-time pioneering (skip the occupation slot, more preaching hours, more financial strain). Generates encounters with worldly people that aren't door-knocks — invitations, conflicts, friendships flagged as "bad association." Possible career/school progression sub-system; college as a deliberate choice with in-group social cost.
- **Personal study minigame.** The third pillar alongside door-knock and meeting — the quiet private discipline of preparing for the Lighthouse Study or just sitting with the Bible alone. Mechanically: a click-through reading interface for a Lighthouse article (3-5 pages, original content per CLAUDE.md guardrails). Paragraphs have questions at the bottom (real WT-study structure); the player answers per the paragraph (low doubt, +conviction) OR pauses on the text in a way that opens an inner-voice beat (doubt-gated, like the meeting page-2 beat — surfaces if `DoubtMeter.value >= 40`). At deeper doubt, scripture cross-references open a "look it up yourself" branch that can surface inconsistencies the article skipped. Energy cost similar to a Hall meeting (-1 / session). Conviction +1 to +2 default; doubt-bearing branches available at the player's discretion. Tone: this is *the room where doubt has the most room to grow*. No audience, no script, no neighbor watching. The inverse of every other game system. Whether to surface a per-week reminder ("you haven't done personal study this week" → small standing-elders or conviction drift) is an open calibration. Pairs naturally with the M6 Family & Home work — family worship is the group analogue.
-

## Content (dialogue, characters, events)

- **Elder archetypes (body of elders variety).** Populate the Hall of Witness elder body with distinct types so meetings, shepherding calls, and judicial situations feel different depending on who's involved. **Canonical mapping locked 2026-05-28:** Brother Phillips (cast.md § 4.1) = *The Shepherd*; Brother Whitcomb (cast.md § 4.2) = *The Pharisee*. The two are paradigmatic instances of those archetypes:
  - *The Shepherd* — **= Brother Phillips (Coordinator of Elders, § 4.1).** The one people actually want to talk to; would notice if you'd been quiet for a few weeks. Locked.
  - *The Pharisee* — **= Brother Whitcomb (Strict Elder, § 4.2).** Knows ks10 cold, runs the strict reading, comes alive in judicial committees. Locked.
  - **PENDING — v1 body of elders target adds (3 new cast.md sub-sections § 4.6 / § 4.7 / § 4.8 + corresponding cast-portraits.md entries):**
    - *The Bureaucrat* — loves territory maps and meeting schedules; not there for people but keeps the machine running. **Why for v1:** mechanically distinct — surfaces when the after-service report (cd8288b) fires monthly hour-tallying; natural Secretary or Service Overseer role. Voice administrative/precise — neither Phillips' warmth nor Whitcomb's doctrinal sharpness.
    - *The Old Guard* — been in since the 70s, talks about how things used to be stricter, slow on policy shifts. **Why for v1:** foils Whitcomb without overlap — Old Guard remembers when rules were harsher AND when people walked the line and survived. Voice slower, anecdotal. Low writing cost; texture-rich.
    - *The Reluctant* — got appointed because there was a gap, does the minimum, would rather be left alone. **Why for v1:** realism beat — every body has one. Mechanically a *relief* — he doesn't fire pressure events. Voice vague, minimum-effort. The player notices the body isn't a monolith.
  - **Defer past v1 (re-rank when their feature ships):**
    - *The Climber* — polished, networked, visibly being groomed for circuit work or a branch invitation. **Defer:** creates political tension with Phillips (groomed-for-Coordinator); better when there's narrative space for body politics in M7+.
    - *The Charmer* — great on the platform, less reliable in the back room. **Defer:** better as a *visiting speaker* (one-shot) than a body member; fits the visiting-speaker pattern flagged in M5.4+ candidates.
    - *The Theologian* — deep in prophecy and types/antitypes, occasionally oversteps and gets walked back by the CO. **Defer:** overlaps Whitcomb's doctrinal sharpness too much in a 5-elder body. Re-consider if you want a doctrinally-rich Lighthouse Study slot distinct from Whitcomb's clipped corrective register.
    - *The Family Patriarch* — heavy on headship, family worship, traditional roles. **Defer to M6:** surfaces in family-of-three-generations scenes; someone the Parent in the Truth holds in regard.
    - *The Quiet One* — reliable, does the shifts, rarely speaks up in meetings but everyone trusts him. **Defer:** by design doesn't surface; low ROI for v1. Could be a cheap background named-but-rarely-speaking add if you want a populated-feeling body.
- **Intermission song scene — pool + social moments (Sunday meeting).** Minimal one-song scaffold landed (single placeholder original between PT and LS). Future work: expand the song pool (multiple originals with last-played exclusion like the speech pools), promote Song to a `Resource` type, add small social-moment opportunities during the song (turning the page for a neighbor, the standing-up shuffle, etc.). Originals only — see CLAUDE.md legal guardrails.
-

## UI / Polish

-

## Audio

-

## Tooling / Dev

-

## Endings

GDD § 8 currently sketches endings at a high level. v1 target set below — each ending is a *character-honest* outcome of the player's accumulated conviction / doubt / standing / relationships state, NOT a verdict on the org. The empathy bar holds at the ending screen too. No ending should read as "the correct one"; each should read as a life someone actually lives.

- **The Elder / Bethelite (the doubling-down ending).** High conviction sustained over years, low or hidden doubt, high standing-elders, completed pioneer service, gets the appointment. Variant A: appointed to the body of elders, stays local, becomes the Coordinator-of-Elders-in-waiting. Variant B: Bethel invitation — the player leaves Maple Street for the branch HQ. Both variants ship as one ending category (slot picked from the player's late-game choices). Tone: *quiet, settled, slightly weary*. The player got what they were taught to want. The cost is everything outside the org — the worldly coworker friendship, the sibling drifting, the unexamined questions — quietly receded.
- **The Bitter Atheist (the loss-of-faith goes hard the other way).** Doubt crossed every threshold, the player formally exited, but the certainty didn't go away — it just inverted. Ends up on ex-JW subreddits, debate forums, replying to JW callout videos at 2am. The org's voice replaced by the *opposite* voice with the same shape. The cost: the social world is gone (shunned) and the new community is online and adversarial. Tone: *sharp, exhausted, lonely*. Do NOT write this as a punchline — the bitterness is *earned* and the loneliness is the real ending. The reddit-atheist signifiers are the *texture*, not the joke.
- **The Hasidic Convert (the structured-but-different ending).** Player leaves, but the shape of high-control religious life was meeting a real need — community, discipline, a tradition that makes daily choices for you. Discovers Orthodox Hasidic Judaism (or a parallel tradition with similar density — Eastern Orthodoxy or traditionalist Catholicism are defensible variants on the same ending slot). New community, new vocabulary, new restrictions, but *real depth* the org didn't have. The cost: still cut off from the original family, still building a life from a late start. Tone: *grounded, attentive, slightly homesick for a place that was never quite home*. Critical writing red line: this is NOT "the player escaped fake religion into real religion." It is "the player found a different way to live the same kind of life, on better terms." The treatment of Hasidic Judaism specifically needs lived-experience texture — `# TODO: authenticity check` on every line.
- **The Quiet Fade (the most common real outcome).** Player doesn't formally exit, doesn't recommit. Just stops going to meetings. Doesn't get disfellowshipped (didn't *do* anything — they just *stopped*). The family stays in contact, awkwardly. The publishers still come to the door at Christmas-ish intervals. Conviction sat at neutral; doubt never crossed the threshold of action. Tone: *small, ordinary, unresolved*. This is the ending most ex-JWs in real life actually reach. The game should let the player land here without it feeling like a failure.
- **The Disfellowshipping Crisis (the accidental exit).** Player did *one specific thing* — a relationship outside the Truth, a refused blood transfusion they recanted on, an association the Strict Elder flagged — and got disfellowshipped. The exit wasn't a choice; the social world is simply gone. Family may or may not stay in contact (Parent in the Truth probably won't; Sibling Drifting probably will; Grandparent depends on the blood-doctrine plot beat). Tone: *shock fading into long quiet*. The triggering event should be authored as something the player *chose* but didn't realize was a one-way door. Do NOT write this as melodrama; the smallness of the inciting beat vs. the size of the cost is the point.
- **The In-Fold Quiet Life (the conviction-stays default).** Player meets the Sister Pioneer (or another in-fold partner), marries, has kids, lives a normal Witness life. Conviction held, doubt never spiked, standing stayed high. This is *not* the Elder ending — there's no appointment, no Bethel, no climbing. Just the ordinary life the org promises and many people actually live. Tone: *modest, real, content within the frame*. Critical writing red line: this ending must read as *defensible* — many real Witnesses live exactly this life and are not unhappy. The game has no business judging the player for landing here.

Open questions:
- **Ending state machine.** Endings should resolve from the accumulated state, not from a final-choice screen. Need to map which late-game state thresholds → which ending.
- **Householder of Note resolution as ending modifier.** The HoN arc per GDD § 7 spans months and may itself trigger an ending (their death, their conversion, their disappearance). Decide whether HoN outcomes are *modifiers* on the main ending or whether one of the HoN paths IS a sixth ending.
- **Multiple-ending lock or single-canonical-per-save?** Disco Elysium ships multiple distinct endings from one save; Pathologic forces commit. Pick one.
- **Endings as Resource subclass.** Probably each ending becomes an `Ending` resource (id, title, eligibility predicate, final-screen text + portrait, doubt/conviction/standing thresholds). Lets late-game scripts query "which ending is currently reachable from this state?" for debug and for the M7 save/load hook.

## Unsorted

-
