# Territory Map — AI Asset Generation Prompts

> ## ⚠ SUPERSEDED — 2026-05-23
>
> This file planned a 14-asset AI generation pass. Andrew shipped
> **3 assets** instead, in this same directory:
>
> - `territory_background.png` — the top-down 4×3 grid (used as
>   the map area background; per-slot house art is NOT generated)
> - `house_painting.png` — single craftsman bungalow (shared
>   across all 12 detail-panel views in v1)
> - `parked_car.png` — vintage sedan (bottom-left decoration)
>
> The implications for M4-LF1:
> - Per-slot grid overlays are **Godot-drawn** (numbered medallions
>   + color-coded outcome badges via `StyleBoxFlat` and `Label`).
>   The map grid is baked into the background asset.
> - Detail-panel polaroid is shared across all 12 houses in v1.
>   Per-house painting variants are out of scope.
> - Decorative banners, ornaments, and badge shapes remain
>   Godot-drawn per the "What we are NOT generating" section below.
>
> The "Shared style descriptor" and the "What we are NOT generating"
> sections below are still useful reference. The 12-house prompt
> list is historical only — read it for context, do not generate
> from it.

---

Reference mockup: `territory_map_v1.png` (this directory).

Generation target session: **Territory Map Visual Polish (M4-LF1)**.

Andrew runs generation between sessions; the polish session drops the
assets into `assets/sprites/` and wires them into `territory_map.tscn`.

---

## Shared style descriptor

Reuse verbatim across every prompt below — consistency across assets
matters more than per-prompt cleverness:

```
painterly 2D illustration, muted palette of sepia, slate blue, cream,
soft gold accents, mid-century children's book aesthetic crossed with
the warmth of Kentucky Route Zero, soft brush textures, late afternoon
golden hour lighting, no figures or people visible, no text or labels
```

GDD § 9 reference: "painterly 2D, muted palette. Suburban America with
a slight oversaturated nostalgia, like *Kentucky Route Zero* if it
were less surreal."

---

## Assets needed (14 total)

### 1. Territory background (1 image)

Sits behind the 4×3 house grid. The houses overlay on top of it; the
background provides the streets, walkways, lawns, and edge texture
visible between/around the houses.

**Target dimensions:** 1280×960 (will be downscaled to fit the map
area in the layout; generate large for crispness).

**Prompt:**
```
Top-down 3/4 perspective view of a quiet 1950s American suburban
neighborhood block, painted illustration, soft concrete walkways
connecting yards, mature deciduous trees, neat front lawns with
patches of garden, no houses visible (houses are removed and added
separately), street running along the bottom edge, sidewalk fences
hinted at the borders, [SHARED STYLE]
```

The "no houses visible" is the tricky part — most image gen tools will
try to add houses. Generate, then either: (a) accept houses in the
background and crop the central grid where actual house tiles will
overlay, (b) regenerate with strong negative-prompt against houses,
or (c) generate WITH houses and let the overlaid sprites just sit on
top (the bg houses are smaller and won't read as conflicting).

### 2. House illustrations (12 unique)

One per slot in the territory grid. Per-house archetype influences
mood the player perceives:
- **6 Polite Refuser**: kept neat, neither inviting nor closed-off
- **3 Hostile Slammer**: slightly less inviting — closed shutters,
  privacy hedges, "no soliciting" energy without being literal
- **2 Curious Seeker**: warmer — open porch, flower beds, slightly
  more inhabited look
- **1 Apostate-reserved (House #7)**: hold for M4.3; for now
  generate a neutral PR-style house

**Target dimensions per house:** 512×512 (square; will overlay on the
grid tiles).

**Vary across the 12** for visual texture: house style (bungalow,
craftsman, cape cod, ranch, dutch colonial, foursquare), trim color
(cream, pale yellow, slate blue, brick red, soft white, olive green,
muted teal), tree placement (left only, right only, both), tiny
elements (porch swing visible, garden gnome, bicycle leaning, etc.).

**Base prompt template (vary the bracketed bits per house):**
```
3/4 view painted illustration of a single-family 1950s American
suburban home, [bungalow|craftsman|cape cod|ranch|dutch colonial|
foursquare], [cream|pale yellow|slate blue|brick red|soft white|
olive green|muted teal] siding, small front yard with grass and a
narrow walkway, [mature oak left|elm right|maples flanking|single
dogwood front], [open porch with chair|closed door slight shadow|
flower beds along the foundation|tidy boxwood hedge|drawn curtains
in front window], [SHARED STYLE], isolated on transparent background
```

**12 specific prompt variants** (one per house — copy-paste these):

1. **House #1 (PR)** — cream bungalow, mature oak left, open porch with chair
2. **House #2 (HS)** — brick red foursquare, elm right, drawn curtains in front window
3. **House #3 (PR)** — pale yellow craftsman, maples flanking, flower beds along the foundation
4. **House #4 (CS)** — soft white cape cod, single dogwood front, open porch with chair and a small wreath on the door
5. **House #5 (PR)** — slate blue ranch, oak left, tidy boxwood hedge
6. **House #6 (HS)** — olive green dutch colonial, elm right, closed door slight shadow, drawn curtains
7. **House #7 (Apostate-reserved, render as PR for now)** — muted teal cape cod, single dogwood front, open porch
8. **House #8 (PR)** — cream foursquare, maples flanking, tidy boxwood hedge
9. **House #9 (CS)** — pale yellow bungalow, oak left, flower beds along the foundation, small bicycle leaning by the porch
10. **House #10 (PR)** — soft white craftsman, elm right, open porch with chair
11. **House #11 (PR)** — brick red ranch, single dogwood front, tidy boxwood hedge
12. **House #12 (PR)** — slate blue cape cod, maples flanking, flower beds along the foundation

Transparent backgrounds: many gen tools struggle with this. If output
has a background, use `rembg` (`pip install rembg` then `rembg i in.png
out.png`) or Photoshop / removebg.com to extract.

### 3. Parked car decoration (1 image)

Bottom-left framing element in the mockup. Vintage sedan, dark blue,
side profile, evokes "the publisher arrived here." Decorative only;
not interactive.

**Target dimensions:** 600×300 (wide aspect; sits at the bottom of
the left panel area).

**Prompt:**
```
Vintage 1950s American sedan, side profile view, deep midnight blue
paint with subtle weathered patina, chrome trim, painted illustration,
parked at the curb with no driver visible, [SHARED STYLE], isolated
on transparent background
```

---

## What we are NOT generating

These ship as code/styled UI rather than AI assets:

- **Banner / panel textures**: the dark navy top banner and the side
  info-card panels — built in Godot with `StyleBoxFlat` (color, border,
  corner_radius) plus optional noise overlay texture for hand-painted
  feel.
- **Outcome badges** (TRACT LEFT, REFUSED, RETURN VISIT, STUDY STARTED,
  NOT VISITED): styled buttons / labels in Godot. Colors should mirror
  the mockup: green for TRACT_LEFT and STUDY_STARTED, golden-amber for
  RETURN_VISIT, deep red for REFUSED, cream/neutral for NOT_VISITED.
- **Numbered medallions (1–12)**: circle + number, Godot-drawn.
- **Decorative ornaments / diamond flourishes**: small SVG or single
  reusable PNG. Andrew can pull a free public-domain mid-century
  ornament from openclipart.org if needed; otherwise generate one and
  reuse 8× across the layout.

---

## After generation — file layout

Drop the generated assets here so the polish session knows where to
find them:

```
assets/sprites/territory/
  background.png              # asset 1
  houses/
    house_01.png              # ...
    house_02.png
    house_03.png
    ...
    house_12.png              # asset 2 (×12)
  decorations/
    car.png                   # asset 3
```

The mapping `house_NN.png` → House #NN matches the
`territory_manager.gd::DISTRIBUTION` slot order. House #7 will get the
real Apostate-mood painting in M4.3; for now it uses the PR-style
placeholder per the list above.

---

## Quality check before the polish session starts

Two things Andrew confirms before next session:

1. **Palette coherence**: lay the 12 house PNGs in a 4×3 grid in a
   throwaway file (Preview / Figma / paint app) and check the muted
   palette holds across all of them. If one house screams (e.g.
   neon yellow instead of pale yellow), regenerate.
2. **Style coherence**: same exercise — do they all read as the same
   illustrator's hand? AI gen tends to drift across long batches;
   regenerate any outliers with a more constrained prompt.

Style drift is the #1 risk with AI-gen across 14 prompts. Coherence
beats individual brilliance for this aesthetic.
