# [7612-S8] Open units drawn as open boxes, not solid blocks

**Status:** ready for session (one decision from Andriy, see section 5)
**Epic:** Open units (7612 Hillside Dr pantry). Runs BEFORE S5-S7: the pantry is blocked on it.
**Date:** 2026-10-03

---

## 1. Intent

Andriy built BL0190 (H.84, d.64,5, 900) from the picker in v0.4 and got a solid block. Probe 270 (read-only)
confirms it: CARCASS is 900 x 645 x 840, 6 faces, 12 edges, no sub-groups. There are no shelves and no opening.

Cause: `Generator.build` (60_generator.rb, the linear path near line 955) draws EVERY linear article as one
`Geometry.box(e, 'CARCASS', ...)`. For a doored unit that is right, because the door covers the box. An open
unit has `front_layout.kind = 'none'`, so it gets no front, and the solid box stays visible. Nothing in core
knows that a cabinet without a front is hollow.

The fix: an article from the open-unit pages draws its CARCASS as an open box. That means 2 sides, top,
bottom, back and its N fixed shelves. The front stays open.

---

## 2. What counts as an open unit (scope)

- In scope: every row of `registry/cesar/open_base_*`, `open_wall_*`, `open_tall_*` (printed p.455-456).
  Each has `opening: none`, `front_layout.kind: none`, `depth_includes_front: true` and `interior_confirmed`
  = "N fixed shelves" ("without shelf" for wall H.36 = 0).
- The test is DATA, not code lists. A unit is open when `front_layout.kind == 'none'`,
  `object_class == 'cabinet'` and `interior_confirmed` names fixed shelves (or "without shelf").
  Panels and fillers also have `kind: none` and are object_class panel / filler, so they must stay solid boxes.
- Out of scope: open end units W.20 (`end_open_*`, p.450-452). Their `interior_confirmed` is empty, and the
  icon shows shelves whose number is not printed. They stay solid until their construction is read. This is
  written on their rows in one line.

---

## 3. Geometry (all mm, unit frame: x right, y back, front plane at y = -22 per panel_front_y_mm)

The CARCASS group keeps the SAME envelope it has today: x 0..W, y -22..D-22, z z0..z0+H. That matters
because 7 readers measure CARCASS by its bounds: selected_top_mm, gap audits, placement beside the selected
unit, filler measure, Apply, and the probes `wbox`. Inside the group the parts are drawn as nested groups,
so the group bounds equal their union, which is the old box.

| Part | Size | Position | Source |
|---|---|---|---|
| SIDE_L, SIDE_R | t x D x H | x 0 and x W-t | t = 22: page title "th. 2.2", finishes table "Thickness 2,2" |
| BOTTOM | (W-2t) x (D-b) x t | between sides, z0 | same |
| TOP | (W-2t) x (D-b) x t | between sides, z0+H-t | same; the icon draws the top between the sides |
| BACK | (W-2t) x b x (H-2t) | between sides, between top and bottom, at the rear | **b = see section 5** |
| SHELF_1..N | (W-2t) x (D-b) x t | equal clear spacing between BOTTOM and TOP | N from interior_confirmed; equal spacing = ASSUMPTION (icon only) |

- Shelf spacing: clear = (H - 2t - N*t) / (N+1); shelf k sits on z0 + t + k*clear + (k-1)*t.
- Example, BL0190 891 x 840 x 645 on a 60 plinth: sides 22 x 645 x 840; clear (840-44-44)/3 = 250,7;
  shelves at 60+272,7 and 60+545,3 (bottom faces).
- Material: the carcass material the box uses now. Edges black (Geometry.box already does this).
- A pure function `Generator.open_carcass_parts(unit)` returns the list of parts `[name, x, y, z, w, d, h]`.
  Headless tests run against it. Build only loops over it with Geometry.box.

---

## 4. Everything that redraws a carcass

- Build (linear path): the open-unit branch draws the parts instead of the box.
- Apply in the panel (width / height change, ground change, shift_body!): verify whether Apply redraws
  CARCASS or moves it. If it redraws, the redraw goes through the same function. If it only moves (shift_body!
  moves every non-PLINTH entity), the nested parts move with the group, which is fine. The session states
  which it is, measured in a probe and not reasoned about.
- Symbols / export: no change. The CSV reads the contract, not the geometry.
- Existing instances: BL0190 247809 in v0.4 was drawn as a block. After deploy Andriy rebuilds it from the
  picker (or Apply, if Apply redraws). No migration code.

---

## 5. Decision needed from Andriy: the back

The page does not print the back. The icon is shaded inside, which reads as closed but is not proof.
Options:
- **B1 - back 22 (2,2), flush with the rear face.** Matches "th. 2.2" for the whole article. Recommended as the
  drawing default until Elda answers.
- B2 - back 4, inset 20 (Standards BACK_T_MM / BACK_INSET_MM, the doored-unit standard).
- B3 - no back (open to the wall).

Whatever is chosen goes in Standards as `OPEN_BACK_T_MM` with STATUS `:assumption_pending_elda`, plus a
line on Q48 (finish inside, back, edges) in `docs/Elda_Open_Questions_v0.1.md`.

---

## 6. Acceptance criteria

- AC-1: BL0190 / BK0190 / PE0190 / CG0190 built from the picker show the opening, the sides and the shelf
  count from their row (H.84 base 2, H.72 wall 1, H.222 tall 5, H.36 wall 0).
- AC-2: The CARCASS group bounds are identical to the old solid box. Test: compare to W x D x H at the same origin.
- AC-3: Panels, fillers, end panels and open end units W.20 are still single solid boxes. Test:
  the whole-registry sweep counts parts per article class.
- AC-4: `open_carcass_parts` tested headless for BL0190 891 and PB0190 (0 shelves).
- AC-5: core 1.9.23, the three suites green via `build/go.sh` (file list rewritten for this story, count stated).
- AC-6: After deploy Andriy builds one BL0190 from the picker in v0.4 himself and looks at it. A read-only probe prints its part list. The pantry continues only after that.

---

## 7. Files

- `src/ucon_cabinet_engine/core/60_generator.rb`: open-unit branch + `open_carcass_parts`.
- `src/ucon_cabinet_engine/core/10_standards.rb`: OPEN_BACK_T_MM, OPEN_PANEL_T_MM = 22, STATUS rows.
- `src/ucon_cabinet_engine/core/00_version.rb`: 1.9.23.
- `tools/test_contract.rb`: AC-2..AC-4.
- `registry/cesar/end_open_*.json`: one line on why they stay solid.
- `docs/Elda_Open_Questions_v0.1.md`: Q48 extended (back).

---

## 8. Implementation notes (2026-10-03)

- AS BUILT, ONE DEVIATION FROM THE TABLE: the back runs full height between the sides and top/bottom stop
  at its face. The table said back between top and bottom with top/bottom at depth D-b, and that leaves
  two empty t x b strips at the rear corners, so the envelope would no longer equal the old box (AC-2).
- `Generator.open_unit?` / `open_shelf_count` / `open_carcass_parts` (pure) / `draw_open_carcass`.
  Boards are nested groups inside CARCASS with no material of their own; CARCASS carries the colour.
- Apply verified by reading the code: `Panel.apply` never redraws CARCASS, only `shift_body!` moves it
  (and the nested boards with it). A test pins that 80_panel.rb never names 'CARCASS'.
- end_open_*.json NOT edited: the reason the W.20 end units stay solid is written once, at `open_unit?`.
- Tests: 6 checks (test_contract 690 -> 696), including a whole-registry sweep: exactly 46 open units,
  each drawn at its narrowest ordered width, no board overlaps, envelope = old box.
