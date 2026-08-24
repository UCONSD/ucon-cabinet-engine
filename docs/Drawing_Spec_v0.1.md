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

## Surfaces mean ownership (SETTLED 2026-08-17)

> **A Cesar object has surfaces. A stand-in for something that is not ours has
> none — edges only.**

A solid grey box for a client's dishwasher reads, on a presentation sheet, as a
cabinet we are selling. That is the same class of error as drawing the wrong
opening symbol: the drawing asserts something untrue. A wireframe volume says
what is actually meant — this space is taken, by something that is not our
order.

- Client appliances (the niche behind a Cesar panel) — edges only, thin grey
  (`#8a8a8a`), on the hideable tag `UCON — Placeholder (not ours)`, so one
  switch clears every placeholder off a sheet.
- The rule generalises to anything we place but do not sell: existing
  appliances, client-supplied furniture, a machine with no Cesar front.
- It does NOT use dashes. Dashed lines already mean movement (opening
  symbols); giving them a second meaning would weaken the first.

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

### Plan symbols sit at the FLOOR (SETTLED 2026-08-17)

Every plan symbol — door swing, drawer travel, fallen leaf — is drawn just above
the floor, not above the unit it belongs to.

Two reasons, both found on a real model: at cabinet-top height the dashed marks
float over the neighbouring worktops and read as clutter rather than as the
unit's own footprint; and a plan view cut below the worktop — the ordinary way
to cut a kitchen plan — loses them entirely, which is the one view they exist
for. At the floor they always sit under the section cut.

This applies to EVERY unit, not only the ones drawn since: doors, drawers and
bottom-hung fronts alike.

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

Thumbnails: not implemented, built with M1.7a.

The hinge-axis rule IS implemented as of 2026-08-17 (core 0.18.0): bottom-hung
fronts draw the inverted V in elevation and the fallen leaf in plan, for both
objects that have one — the laundry unit (B80614 / B90614) and the dishwasher
panel (V80530 / V80630 / V80730). The geometry lives in a pure function,
`Symbols.bottom_hung_marks`, so the rule is checked headless and the renderer
only draws what it returns; door version 75 shortens the elevation apex and the
plan projection together, because both read the same front height.

Still unrendered: the pull-out door (printed p.36, B70100 / B80100 / B80300 /
B80400) — it neither swings nor is a drawer, and the travel of its mechanism is
not in the catalog, so it deliberately draws nothing.

Test on a real model and correct the spec if the drawing argues with it — the
spec is the authority, but reality gets a vote.

---

## Corners: the seating carries our front gap, the catalog's node does not

**Added 2026-08-24, from Avenida Primavera. Applies to EVERY corner class.**

A printed corner node - the `W. 100x43` style notation on printed p.42 and its
equivalents in the tall and wall chapters - is a **carcass** dimension. It is
taken carcass to carcass and knows nothing about how far our fronts stand proud
of the carcass plane.

Along a straight run that costs nothing: every front is pushed forward by
`FRONT_GAP_MM + FRONT_T_MM`, so they share a plane. **At a corner the axes
swap.** The offset that was *forward* in one run becomes *sideways* in the
other and eats length along the wall. Seat the node raw and the neighbouring
run's front lands `FRONT_GAP_MM` short of the outer face of the corner filler.

**Rule: a corner unit is seated `nominal + FRONT_GAP_MM` from the corner,
measured along the wall it backs onto.** The catalog number is not altered; only
the seating moves. In the model the gap appears as clear space between the far
edge of the `WASTED_SPACE` box and the perpendicular wall.

Three things this rule deliberately does NOT do:

- **It does not grow the wasted-space box.** That box is `nominal - carcass`, a
  quantity derived from the catalog, and mixing our drawing constant into it
  would put a UCON decision inside a Cesar number.
- **It does not touch `Placement.span_mm`.** The unit still occupies carcass
  plus wasted measured from its own origin; the shift is already in where that
  origin landed. Applying it twice would double the gap.
- **It does not change any code, price, order line or printed dimension.**

The filler leg has always carried this gap - it is drawn off the front plane and
reaches `-(FRONT_GAP_MM + FILLER_MM)` - so the rule is best read as making the
two legs of a corner agree, not as a new allowance.

**The tall corners take it unchanged, and so do the wall corners**, with their
own filler size (5x5 rather than 8x8): the filler size is not part of the rule.

### CORRECTED THE SAME DAY — the rule above is wrong, and this is the right one

**Added 2026-08-24, hours after the section above. Rule 9: dated and added, not
erased, because the mistake is why the check exists.**

The symptom was real. The neighbouring run's front did miss the outer face of
the 8x8 filler by `FRONT_GAP_MM`. **The body that had to move was the filler,
not the unit.**

The mismatch runs **along the wall**, not through the depth. A run standing
against the perpendicular wall has its carcass front at `wall - depth` and its
FRONT one gap further out. The corner's filler leg along the width reached a
full 80 from the door — and so overshot the very front it exists to meet, by
exactly that gap.

**The rule: the printed 8x8 is a NOMINAL. The leg that runs along the width is
drawn at `FILLER_MM - FRONT_GAP_MM` — 77 — because it meets a front, not a
carcass. The return leg meets nothing and keeps its 80.** The L is 77 x 80.

And **the seating takes the printed node raw**. The `+ FRONT_GAP_MM` proposed
above has been reverted. Cesar's own SketchUp export of estimate 2026/30831
seats the corner carcass at exactly `nominal - carcass` = 250 mm from the
perpendicular wall, with nothing added.

**One divergence stays, and it is recorded rather than fixed.** That same export
draws the base corner 900 x 700 — depth 620 + 80 measured from the CARCASS —
where we draw 703, because our filler stands on the front plane. Both are
defensible readings of an 8x8 panel and they differ by the gap. It does not
affect whether the fronts meet, and it is written into
`registry/cesar/_manifest.json` under `factory_confirmations` → `contradicts`.

**What this cost:** a symptom pointed at two bodies, and the first attempt moved
the one that was easy to see. The measurement that settled it — the factory's
own file — had been in hand for an hour.
