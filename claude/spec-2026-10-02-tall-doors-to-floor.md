# [7612-S1] Tall-row doors lengthened to 10 mm above the floor

**Status:** draft
**Epic:** 7612 Hillside Dr — factory drawing set
**Date:** 2026-10-02

---

## 1. Intent

On 7612 the whole tall row gets doors with an INCREASED height (Andriy, 2026-10-02): the carcasses stay where
they are (Tall H.222 for base H.84 on the 60 plinth, top 2280), but every front of the row runs down to 10 mm
above the floor, the line set by the drawn passage door (10..2280). The plinth disappears behind the doors.
The catalog prints no door height INCREASE for these articles (Kitchen System printed p.548 prints reductions
only; plinth H.1 "doors on the ground" is printed for Revego / Hide & Seek, printed p.183 / p.196), so this is
a per-object request to Cesar, exactly like FRONT SPLIT (core 1.9.13) and WIDTH INCREASE (Q39): the engine must
DRAW it and the order must SAY it, without inventing an article. Elda question to be written (Q40).

---

## 2. Input/Output matrix

| # | Input | Expected output |
|---|---|---|
| 1 | Object with variant `DOOR TO FLOOR` value `10` (mm above floor), carcass on plinth 60 | Lowest front slab's bottom drawn at z = 10 (floor-relative); its top unchanged; plinth box not drawn in front of it |
| 2 | Same, after Apply in the properties panel | Same geometry as row 1 (variant read on rebuild, like FRONT SPLIT) |
| 3 | CK7744 (stack of fronts) with the variant | Only the BOTTOM front grows (by 50 on plinth 60); the niches and the upper door unchanged |
| 4 | CH4640 (USA fridge door) with the variant | The door runs 10..2280 (2270) |
| 5 | CG0151 (tall filler) with the variant | Filler front 10..2280; today it is drawn at −40..2280 (old plinth-100 record) — the variant fixes the drawing, the record of its ground is corrected to 60 |
| 6 | Variant value ≤ 0, ≥ the plinth height, or not a number | Refused by name; nothing redrawn |
| 7 | Variant on an object with no front (panel, shelf, worktop) | Refused by name |
| 8 | Export | The variant prints as its own line under the article, "DOOR HEIGHT INCREASE to N mm above floor - REQUESTED, NOT PRINTED"; no surcharge code invented |

---

## 3. Acceptance criteria

- AC-1 — On v0.4 after the run, the tall elevation (scene 02) shows one bottom line at 10 for CG0151, CK7744, both CH4640 and the passage door; the C00130 corner panel stands at 0.
- AC-2 — Headless suites green under /usr/bin/ruby 2.6; new checks cover rows 1, 3, 6, 7, 8.

---

## 4. NOT-list

- DO NOT add a key to the Object Contract — it is a variant, as FRONT SPLIT is (contract §1.4).
- DO NOT change plinth/ground logic (UCON_GROUND, plinth_from_run) beyond the CG0151 record in row 5.
- DO NOT touch the passage door object (UCON_CUSTOM) or the d.75 corner panels.
- DO NOT invent a surcharge code or a catalog fact for the increase.
- DO NOT refactor front_slabs / FRONT SPLIT code beyond what row 1–3 need.

---

## 5. Non-functional

_none_

---

## 6. Files to read first

| Path | What to look at | Why |
|---|---|---|
| src/ucon_cabinet_engine/core/60_generator.rb | `FRONT_SPLIT_KEY` (~l.2923–2960), `front_slabs`, `draw_front_slab`, `draw_plinth` | the precedent: a variant read on rebuild changes the drawn fronts |
| src/ucon_cabinet_engine/core/85_export.rb | `variant_rows` | how a variant reaches the order |
| claude/project-7612-hillside-dr-2026-09-24.md | entries 2026-09-28 (passage door 10..2280), 2026-10-02 | the decision and the objects |
| tools/test_contract.rb | the FRONT SPLIT checks | pattern for the new checks |

---

## Pre-session check
- [x] Intent fits in half a page.
- [x] Everything expressible as a table is in the table.
- [x] NOT-list is not empty.
