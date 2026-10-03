# [7612-S3] A front that projects below its carcass (handle-free wall units)

**Status:** ready for session
**Epic:** 7612 Hillside Dr — factory drawing set
**Date:** 2026-10-02

---

## 1. Intent

Andriy, 2026-10-02: the six sink-wall uppers (PF0631 cut to 550, wall_hung 1465..2425) get doors that run
**22 mm below the carcass**, over the 22 mm light shelf beneath them; the shelf's front stops 25 mm behind the
back of the doors, so the slot behind the lowered door is the finger grip - no handles. The catalog knows the
thing: Kitchen System printed p.554-557 (Fronts) - "To determine the cost of floor-standing / projecting door
fronts, refer to the cost of the next standard-height front up". So it is a priced, per-object order fact, like
FRONT SPLIT and DOOR TO FLOOR (core 1.9.13 / 1.9.18): the engine must DRAW it and the order must SAY it, without
inventing a code. DOOR TO FLOOR is measured from the floor and refuses hung units by design; this one is measured
from the carcass bottom and is meant for hung units.

---

## 2. Input/Output matrix

| # | Input | Expected output |
|---|---|---|
| 1 | Wall-hung PF0631 @550 (mount_bottom 1465, carcass 960) with variant `FRONT BELOW` value `22` | Lowest front's bottom at carcass bottom − 22 (z 1443 absolute); top unchanged (2425); width unchanged (550) |
| 2 | Same after Apply in the panel (hinge change etc.) | Same geometry (variant read on rebuild, like FRONT SPLIT / DOOR TO FLOOR) |
| 3 | Door symbols (elevation V, plan, 3-D open leaf) | Follow the lowered front (front_span_mm already takes slabs - check it covers this) |
| 4 | Value ≤ 0, not a number, or > 100 | Refused by name, nothing redrawn |
| 5 | Object with no front | Refused by name |
| 6 | FRONT BELOW and DOOR TO FLOOR on the same object | Refused by name (two answers to one question) |
| 7 | Floor-standing unit with FRONT BELOW | Allowed only if the drop does not reach the floor (bottom > 0); otherwise refused with a pointer to DOOR TO FLOOR |
| 8 | Export | Variant line "FRONT PROJECTING N mm below the carcass - priced as the next standard-height front up (printed p.554)"; no code invented |

---

## 3. Acceptance criteria

- AC-1 — Headless suites green under /usr/bin/ruby 2.6; checks for rows 1, 4, 5, 6, 8 with concrete numbers.
- AC-2 — On v0.4, after the probe writes the variant on the six PF0631, their fronts run 1443..2425 and the
  door V follows.

---

## 4. NOT-list

- DO NOT add an Object Contract key - it is a variant.
- DO NOT change DOOR TO FLOOR's behaviour or its messages (only the row-6 mutual refusal touches it).
- DO NOT change mounting / ground logic, the light shelf, or the side panels.
- DO NOT invent a surcharge code.

---

## 5. Non-functional

_none_

---

## 6. Files to read first

| Path | What to look at | Why |
|---|---|---|
| src/ucon_cabinet_engine/core/60_generator.rb | `DOOR_TO_FLOOR_KEY`, `door_to_floor_check`, `lower_to_floor`, `bottom_fronts`, `effective` | the precedent to mirror |
| src/ucon_cabinet_engine/core/70_symbols.rb | `front_span_mm`, `draw_open_leaf` | symbols already follow slabs since 1.9.19 |
| src/ucon_cabinet_engine/core/85_export.rb | `variant_description`, `door_to_floor_refusal` | how the order line is printed |
| src/ucon_cabinet_engine/core/80_panel.rb | `effective_slabs` (the gola stack branch wraps lower_to_floor) | same wrap needed |
| tools/test_contract.rb | DOOR TO FLOOR checks | pattern |
