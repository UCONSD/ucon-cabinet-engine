# [7612-S7] Trilli into the registry - the code depends on the finish

**Status:** draft - first story of a new grammar, owner in the loop
**Epic:** Open units in the picker (7612 Hillside Dr pantry) - S7 of S4..S7
**Date:** 2026-10-03

---

## 1. Intent

Kitchen System printed p.471-484: Trilli, open boxes with compartments for base (h.36-78), wall (h.24-120)
and tall (h.198-234) use, d.27,5 / 37,5, widths 30-240, optional Mini Noor light, about 200 codes. **New
grammar: the code changes with the price band.** At d.27,5 the band 5 / 6 / 8 codes are `GQ…` / `GO…` /
`GP…`; at d.37,5 `GU…` / `GV…` / `GW…`; the tail carries position (B base, P wall, C tall), height letter and
width. Today a code is one article with a price per band; here one position is three articles. Before any
data is written, Andriy decides how the picker shows it (one row with the band chosen at order, or three
rows). That is the owner-in-the-loop part; the rest is extraction.

---

## 2. Input/Output matrix

| # | Input | Expected output |
|---|---|---|
| 1 | One Trilli position (e.g. h.58,5, 2 compartments, W.30, d.27,5) | One position, three codes `GQBJ03 / GOBJ03 / GPBJ03` with their points, shown as Andriy decides in §1 |
| 2 | Finish chosen in RR oak | Band 8 code (`GP` / `GW`) - band read from printed p.469, not from the open-units page |
| 3 | Every position on printed p.473-484 | Present with h, d, W, compartment count, "surcharge for lights" |
| 4 | Countertop Trilli (p.478, `GQBB62`, `GQBB67` …) | Extracted with what the page prints; anything unprinted is said to be unprinted |
| 5 | "See rules on page 516" | Recorded as a broken reference (printed p.516 is broom-cupboard accessories); the rules are not guessed |
| 6 | Build | Open envelope W x d x h, front `none`; compartments not modelled (domain rule 4) |

---

## 3. Acceptance criteria

- AC-1 - The finish-to-code rule is in ONE pure place, headless-tested both ways (band → code, code → band).
- AC-2 - If the rule needs a contract key, the session stops and writes a contract revision proposal instead of adding the key.
- AC-3 - `catalog_map` Trilli entry `extracted`, dated. Suites green.

---

## 4. NOT-list

- DO NOT apply the finish-in-code grammar to any other section.
- DO NOT add keys to the Object Contract without a versioned revision (domain rule 3).
- DO NOT model compartments, dividers or lights as geometry.
- DO NOT touch the 7612 model.

---

## 5. Non-functional

_none_

---

## 6. Files to read first

| Path | What to look at | Why |
|---|---|---|
| `sources/factory/CESAR - 2 Kitchen System.pdf` | PDF 471-486 (printed 469-484) | The source |
| `registry/cesar/tops_ceramic_linear_elements.json` | `points_per_lm_by_group_and_band` | The nearest precedent: an order axis that is not in the code |
| `docs/UCON_Object_Contract_v2.md` | variants, §4.2 | Where a finish-dependent code would have to live |
