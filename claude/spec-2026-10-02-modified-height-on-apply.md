# [7612-S2] A modified height survives Apply

**Status:** ready for session
**Epic:** 7612 Hillside Dr — factory drawing set (engine hardening)
**Date:** 2026-10-02

---

## 1. Intent

Found by the review of core 1.9.19 (2026-10-02). `Generator.effective` restores what the ORDER chose on top of
the registry row - mounting, ground, FRONT SPLIT, DOOR TO FLOOR and, since 1.9.19, a WIDTH INCREASE / REDUCTION -
but not a HEIGHT INCREASE / REDUCTION. So Panel#apply on a cabinet whose height was modified (e.g. B80601 cut
780 → 720, CK7744 at 2160) rebuilds its fronts, plinth and symbols at the CATALOG height over the reduced
carcass, and `attributes_patch` writes the catalog front height into the contract. Silent: the drawing then
disagrees with the order line. Panels (C00130 2280, B70130 720 in 7612) carry the wrong height in `chosen` but
Apply draws nothing from it today. In v0.4 no front-carrying object has a height modification (probe 242), so
this is latent - fix it before one exists. Same shape as fix B of 1.9.19.

---

## 2. Input/Output matrix

| # | Input | Expected output |
|---|---|---|
| 1 | Fixed-height cabinet with variant HEIGHT REDUCTION and height_mm 720 (catalog 780), e.g. B80601 | `effective` returns height 720; Apply's fronts / symbols / plinth use 720; contract front_height_mm 720 (gola: 690) |
| 2 | Same with HEIGHT INCREASE (if the registry allows one for the code) | `effective` returns the increased height |
| 3 | Stray height_mm with NO height variant | registry height kept (a stray number cannot out-vote the registry - mirror of the width rule) |
| 4 | Sheet panel with height_range_mm (DV731Q 43) | ordered height restored unconditionally, as the width is for a sheet |
| 5 | End panel C00130 2280 / B70130 720 | `effective` returns 2280 / 720; Apply changes nothing in geometry (dz 0) |
| 6 | Tall stack (CK7744) reduced in height | the change lands where the catalog's modification rule puts it; if the rule is not printed for stacks, REFUSE by name rather than guess |
| 7 | Height + DOOR TO FLOOR together | lowered front computed from the restored height; top of front = top of reduced carcass |

---

## 3. Acceptance criteria

- AC-1 — Headless suites green under /usr/bin/ruby 2.6; checks for rows 1, 3, 4, 5, 7.
- AC-2 — On v0.4 after Reload core, Apply on C00130 and B70130 leaves them at 0..2280 and 2280..3000 (probe check).

---

## 4. NOT-list

- DO NOT add an Object Contract key.
- DO NOT change how a height is ORDERED (Registry.with_ordered_height's rules and refusals stay as they are).
- DO NOT touch the width logic of 1.9.19, FRONT SPLIT or DOOR TO FLOOR beyond row 7.
- DO NOT redraw carcasses in Apply (Apply never redrew them; keep it so).

---

## 5. Non-functional

_none_

---

## 6. Files to read first

| Path | What to look at | Why |
|---|---|---|
| src/ucon_cabinet_engine/core/60_generator.rb | `effective`, `WIDTH_MOD_KEYS` / `width_modified?` (1.9.19) | the precedent this mirrors |
| src/ucon_cabinet_engine/core/50_registry.rb | `with_ordered_height` (~l.678-720) | how a height is ordered and refused |
| src/ucon_cabinet_engine/core/80_panel.rb | `apply` (~l.682-770), `attributes_patch` (~l.171 `front_height_mm`) | where the catalog height leaks into the contract |
| tools/test_contract.rb | the 1.9.19 width checks | pattern for the new checks |
