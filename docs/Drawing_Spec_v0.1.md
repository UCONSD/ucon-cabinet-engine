# Drawing spec v0.1 — 2026-08-16

The AUTHORITY for how the engine draws picker thumbnails, opening symbols and
LayOut marks. Procedural / generative graphics: images are drawn from data by
rules (a "grammar of graphics" — data → visual marks), never stored as static
assets (one deliberate exception: iso placeholders, see below).

Pattern: this spec is the authority, the renderer is the implementation —
exactly as Object Contract → 20_contract.rb. New object types (sink, corner)
add their rule HERE, not as ad-hoc SVG. The mockup thumb_options.html was a
first hand-drawn draft and is superseded by this spec.

## Global convention (SETTLED via the symbols work)

- Lines: thin, gray (`#8a8a8a`). Opening symbols dashed, on two hideable tags
  (front / plan). Iso faces: light top (`#ececec`), medium side (`#dcdcdc`),
  white front.
- Units are envelope-only; the reveal is recorded, not drawn.

## Front schematic — per unit kind (SETTLED)

- **single**: rectangle + dashed V, base at the hinge edge, apex at the
  opening edge mid-height.
- **vertical_split (n)**: rectangle + n−1 division lines + a dashed V per leaf.
- **horizontal (drawer stack)**: rectangle + bands from `front_layout.heights`
  in real proportion + one dashed diagonal per band (top-left → bottom-right).
- gola: bands/V follow the shortened front height; the 30 mm zone stays empty.

## Hinge axis — one rule, three drawings (SETTLED 2026-08-17)

The V is not three symbols, it is one rule applied to an axis:

> **The base of the symbol lies ON the hinge axis; the apex points at the
> opening edge.**

Everything else follows without a second rule:

- **Side-hung door** — base vertical at the hinge stile, apex at the handle
  stile: the V lying on its side. Side comes from `hinge_side` (rh/lh).
- **Bottom-hung door** — base along the bottom edge, apex up at mid-width:
  **Λ**, an inverted V.
- **Top-hung** — the same figure the other way up (V). None in the catalog yet;
  it needs no new rule if one appears.

### Where the axis comes from — cabinet vs appliance

This distinction is the point, not a detail:

- **A cabinet's hinge axis is DATA.** Sometimes a per-order axis that must
  never be guessed (`hinge_side` rh/lh); sometimes a stated fact of the unit
  type — printed p.36 "Base unit with laundry basket — 1 bottom-hung door"
  (B80614, B90614) is bottom-hung by catalog, not by choice.
- **An appliance panel's axis is a CONSTANT OF ITS CLASS.** A dishwasher panel
  bolts onto the machine's own door; the hinges belong to the appliance, not to
  the cabinet, and a dishwasher has no other way of opening. So the renderer
  draws Λ with no input at all — nothing to ask the user, nothing to store as a
  variant, and no Elda question. The source agrees: the dishwasher door is
  specified "without fixing holes" and the washing-machine door "without holes
  for hinges", because there are no hinges on the panel.
- Order consequence: an appliance panel's order line is the FRONT only — no
  hinge, no mechanism. One exception is printed p.47, where the 75 cm version
  needs `GBBF01`, a stainless steel cabinet carrying the door-bearing
  mechanism, and that IS a Cesar order line.

### Plan view — the leaf drawn where it actually goes

Same principle as the drawer: dashed, real geometry, fully open position.

- **Side-hung**: the real 22 mm leaf swung 90°.
- **Bottom-hung**: the leaf falls to horizontal, so the plan shows a dashed
  rectangle in front of the unit — width = front width, projection = the
  FRONT HEIGHT (780 handle, 750 gola). Pure geometry, no hardware table
  needed, unlike the drawer's runner travel.
- **Drawer**: real travel from the runner table, as already built.

Useful side effect worth keeping: on a plan sheet the projection immediately
shows whether an open dishwasher or laundry door blocks the aisle. That is
what a plan is for.

## Iso thumbnail — TYPE level (DECISION 2026-08-16)

- Direction: isometric, catalog-like. The generated iso is NOT the final form.
- **Placeholders: iso line-drawings extracted from the Cesar catalog PDF**,
  one per unit TYPE (matches the catalog's own usage). Copyright: acceptable
  for an internal dealer tool selling Cesar; becomes a real question only if
  the tool is distributed beyond UCON (not legal advice — a flag).
- **Data model:** a unit type carries an OPTIONAL `thumbnail` field. Present →
  use it. Absent → the engine draws a generative iso (fallback). So generative
  is the DEFAULT; a placeholder is an explicit opt-in. "Swap to our own later"
  = remove the field; new sections without one are covered automatically.
- Result card still uses the GENERATED front schematic for the specific code,
  so size and configuration distinguish (the type iso does not vary by size).
- Flame / other catalog pictograms: IGNORED for now (meaning unconfirmed —
  never reproduce a symbol whose meaning we have not verified).

## To be defined (when M1.7a is built)

- Generative iso rules (proportions, shading, whether the open door is shown)
  — good enough to eventually replace the PDF placeholders.
- Badges/pictograms grammar, IF wanted — only for markers whose meaning is
  source-confirmed (gola-capable, drawers, …). Not the flame.
- 78/75 door-height indicator (optional decoration).

## Status

Thumbnails: not implemented, built with M1.7a. The hinge-axis rule above is
settled but not yet rendered: `70_symbols.rb` today draws side-hung doors and
drawers only, and no bottom-hung front exists in the registry yet (B80614 /
B90614 are among the p.36 codes still unextracted, and the dishwasher panel
comes with the placeholder task). Implement it when the first bottom-hung
front lands, then test on a real model and correct the spec if the drawing
argues with it — the spec is the authority, but reality gets a vote.
