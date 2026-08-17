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

Not implemented. Built with M1.7a (paired with M1.7 sink section). This spec
is authored first so the renderer follows defined rules, not ad-hoc SVG.
