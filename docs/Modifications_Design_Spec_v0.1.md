# Modifications design spec v0.1 — 2026-08-16

Design for handling factory-modified elements. NOT YET IMPLEMENTED — build
only when a real project needs a modified unit (demand-driven, per CLAUDE.md).
This spec + the registry `modifications` section are the ready groundwork.

Source: `sources/raw_dump/Modifications_Customisations_Source_Extract_v0.1.xlsx`
(rows "confirmed from source"), from CESAR - 2 Kitchen System.

## The real problem (not geometry)

The deliverable is the factory ORDER, not the 3D. The danger: a modified
cabinet shipped with only its standard code → factory makes the standard.
The whole feature exists to make that state impossible to reach or export.

## Key source fact that shapes everything

A modification does NOT create a new cabinet code. The base article code
stays; the modification is a SEPARATE order line — a modification code
`989xxx` + points. An order line for a modified unit is:

```
B80601            (base code — unchanged)
+ 989370          (width/height reduction, 138 pts)
+ 989350          (depth reduction base, 92 pts)
```

So the base code is unchanged but the unit CARRIES modification codes. The
factory makes the standard precisely when the 989 line is dropped. The
engine's job: when geometry diverges from catalog, AUTO-ATTACH the correct
modification code(s), and never let the exporter lose them.

## Modification code map (verified, base/wall/tall)

| Change              | base / wall | tall     | notes                          |
|---------------------|-------------|----------|--------------------------------|
| Width reduction     | 989370 (138)| 989380 (227) | subject to exclusions      |
| Height reduction    | 989370 (138)| 989370 (138) | min height NOT in source (Q3)|
| Depth reduction     | 989350 (92) | 989360 (143) |                            |
| Off-square corner   | 989330 base / 989320 wall | — | dedicated workmanship   |
| Shaping/special red.| 989340 (274)| 989310 (358) | status unclear; no interior accessories |
| Adjustable feet H.5 | 989053 (22) | 989053   |                            |
| Wall-hung fixings   | 989410 (42) | 989411 (84) | 240 kg/pair               |
| Matt-lacquered carcass | 989400 (172) base / 989401 (120) wall | 989402 (417) | no dim change |
| Non-assembled       | +20% carcass surcharge | | no code shown             |

Each modification is charged/listed SEPARATELY (width + depth = two lines).

## Hard rules (must be enforced by the validator)

- **Width modification PROHIBITED for:** appliance units; units with interior
  drawers / jumbo drawers; pull-out units; units with mechanisms; tall/wall
  units with framed glass doors. "Do not infer modification availability from
  a similar standard cabinet."
- **Depth reduction max (drawer/jumbo units):** D.350 → −20 (min 330);
  D.620 → −90 (min 530); D.670 → −40 (min 630). Implied minimums (arithmetic),
  subject to Cesar confirmation.
- **Depth increase (side panel only):** 620→670→720→770, +50 mm steps,
  41 pts, ONLY the listed heights; applies to one side panel.
- **Master rule:** always check feasibility with Cesar. Every modification is
  feasibility-pending → PRELIMINARY by definition.
- Fronts of a modified unit are reduced and FACTORY-finished like standard
  fronts (never field-cut) — the front follows the carcass modification.

## Design (additive, no heavy object — the anti-DC)

A modification is a data delta on a catalog unit, not a new object class. The
unit stays a `cabinet`. Proposed additions to the Contract (a future v1.3):

- `base_code` — the standard code the unit derives from (immutable identity).
- `modifications` — array; each entry: `{ type: width|height|depth|…,
  code: "989xxx", delta_mm, points, source_ref }`.
- Existing `code` stays the base code; `code_status`/`status` → PRELIMINARY
  whenever `modifications` is non-empty.

**Behaviour:** the panel gets constrained dimension editing (carcass W/H/D,
door, shelves — the v1 scope). When a value diverges from the catalog
standard for this `base_code`, the engine AUTO-ATTACHES the right modification
code, records the delta, and drops the unit to PRELIMINARY. No mode switch,
no "make modifiable" click — divergence itself is the trigger, so it cannot
be forgotten.

**Contract invariant (headless-testable):** dimensions differ from the
catalog standard ⟺ `modifications` non-empty ⟺ status = PRELIMINARY. A unit
cannot hold diverged geometry with an unmodified code. The validator also
rejects prohibited-family width mods and out-of-range depth reductions.

**Exporter (M1.10):** emits base code + each modification code as order
lines — where the safety actually lands.

**Visual:** modified units get a visible on-screen marker (tag/colour) so a
modification is obvious in the model too.

## Rules as data

The tables above go into the registry (`_manifest.json` → `modifications`
section, added below in v0.1 with the confirmed codes/limits). The validator
and panel read them; nothing catalog-specific is hardcoded.

## Scope

v1: reduce carcass width/height/depth, door follows, shelf count. Out of
scope for now (not precluded — the `modifications` array can hold new typed
entries later): adding structural elements, shaping (989340/989310, status
unclear), appliance-driven custom cabinets, off-square corners.

## Where this fits in the non-standard spectrum

(1) European standard code as-is; (2) US Elements — a catalog section;
(3) catalog filler/end/open units (Cesar section, printed p.457 — reach here
first for simple infill); (4) modified standard — THIS spec (base + 989xxx);
(5) bespoke / made-to-measure — no code, UCON-defined
(`docs/Bespoke_Elements_Design_Spec_v0.1.md`); (6) appliance placeholder —
client's own appliance stand-in, panel-ready, no code. This spec is only (4).

## Elda Q3

Recorded in Elda_Open_Questions. Unknowns from the extract: minimum resulting
width/height after reduction (source says "available", no limit); the 989346
drawer-width-reduction reference that contradicts the interior/jumbo-drawer
prohibition. Architecture does not depend on the answers — they fill in
numeric limits the validator will enforce.
